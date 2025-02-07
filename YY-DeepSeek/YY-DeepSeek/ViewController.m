//
//  ViewController.m
//  YY-DeepSeek
//
//  Created by yinyao on 2025/2/6.
//

#import "ViewController.h"
#import "NetworkService.h"


#define kIsIphoneX (([[UIApplication sharedApplication] statusBarFrame].size.height > 20))

#define kBottomSafe (kIsIphoneX?39:0)

// 设备Size
#define kWidth ([[UIScreen mainScreen] bounds].size.width)
#define kHeight ([[UIScreen mainScreen] bounds].size.height)

// 输入框高度
#define kInPutHeight 49
#define kInPutSpace  44


@interface ViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property(nonatomic, strong) NSMutableArray<NSString *> *messageList;
// 消息列表
@property(nonatomic, strong) UITableView *messageTableView;

// 文本输入框
@property (nonatomic, strong) UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    // 消息列表
    self.messageList = [NSMutableArray array];
    [self createUI];
    
    //添加键盘监听
    [self addKeyboardNote];
}


// MARK: - UI布局
- (void)createUI {

    // 消息列表视图
    CGFloat tableY = 64;
    CGFloat tableHeight = kHeight - tableY - kInPutHeight - kInPutSpace;
    self.messageTableView = [[UITableView alloc] initWithFrame:CGRectMake(10, tableY, kWidth - 20, tableHeight) style:UITableViewStylePlain];
    self.messageTableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.messageTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.messageTableView.delegate = self;
    self.messageTableView.dataSource = self;
    [self.messageTableView registerClass:[UITableViewCell class]
                  forCellReuseIdentifier:@"MessageCell"];
    [self.view addSubview:self.messageTableView];
    
    //添加文本输入框
    [self.view addSubview:self.textView];
}

// MARK: - 发送消息
- (void)sendMessage:(NSString *)msg {
    
    [self.messageList addObject:[NSString stringWithFormat:@"Me:\n%@", msg]];
    [self.messageTableView reloadData];

    if (self.messageList.count > 0) {
      NSIndexPath *indexPath =
          [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
      [self.messageTableView
          scrollToRowAtIndexPath:indexPath
                atScrollPosition:UITableViewScrollPositionBottom
                        animated:YES];
    }
    
    [[NetworkService shared] sendMessageToDeepSeek:msg completion:^(NSString * _Nonnull response, NSError * _Nonnull error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[DeepSeek] error = %@", error);
            NSLog(@"[DeepSeek] response = %@", response);
            
            if (error == nil && response != nil) {
                [self.messageList addObject:[NSString stringWithFormat:@"DeepSeek:\n%@", response]];
            }
            
            [self.messageTableView reloadData];

            if (self.messageList.count > 0) {
              NSIndexPath *indexPath =
                  [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
              [self.messageTableView
                  scrollToRowAtIndexPath:indexPath
                        atScrollPosition:UITableViewScrollPositionBottom
                                animated:YES];
            }
            
        });
    }];
}



// MARK: - UITableView代理方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
    return self.messageList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell"
                                                            forIndexPath:indexPath];

    cell.textLabel.text = self.messageList[indexPath.row];
    cell.textLabel.numberOfLines = 0;
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}



// MARK: - UITextViewDelegate
// MARK: - 键盘上功能点击
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    if ([text isEqualToString:@"\n"]) {// 点击了发送
        // 发送文字
        NSLog(@"发送文字: %@", textView.text);
        
        [self sendMessage:textView.text];
        
        textView.text = @"";
        
        [self.view endEditing:YES];
        return NO;
    }
    return YES;
}


// MARK: -  添加键盘通知
- (void)addKeyboardNote {
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // 1.显示键盘
    [center addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillShowNotification object:nil];
    
    // 2.隐藏键盘
    [center addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillHideNotification object:nil];
}

// MARK: -  键盘通知执行
- (void)keyboardChange:(NSNotification *)notification {
    
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect newFrame = self.textView.frame;
    newFrame.origin.y = keyboardEndFrame.origin.y - newFrame.size.height;
    
    if ([notification.name isEqualToString:@"UIKeyboardWillHideNotification"]) {
        newFrame.origin.y -= kBottomSafe;
    }
    self.textView.frame = newFrame;
    
    [UIView commitAnimations];
}


// MARK: - 文本输入框
- (UITextView *)textView{
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.frame = CGRectMake(10, kHeight - kInPutHeight - kInPutSpace, kWidth - 20, kInPutHeight);
        _textView.backgroundColor = UIColor.redColor;
        _textView.delegate = self;
        _textView.font = [UIFont systemFontOfSize:17];
        _textView.returnKeyType = UIReturnKeySend;
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        //UITextView内部判断send按钮是否可以用
        _textView.enablesReturnKeyAutomatically = YES;
        
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _textView.layer.cornerRadius = 4;
        _textView.layer.masksToBounds = YES;
        _textView.layer.borderColor = [[[UIColor lightGrayColor] colorWithAlphaComponent:0.4] CGColor];
        _textView.layer.borderWidth = 1;
    }
    return _textView;
}

@end
