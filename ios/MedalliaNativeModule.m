#import "MedalliaNativeModule.h"
#import <React/RCTLog.h>
#import <UIKit/UIKit.h>

@interface MedalliaNativeModule ()
@property (nonatomic, strong) RCTPromiseResolveBlock medalliaPromise;
@end

@implementation MedalliaNativeModule

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents {
    return @[@"MedalliaFeedbackReady", @"UserDataInjected", @"MedalliaFormAction"];
}

RCT_EXPORT_METHOD(showFeedbackForm:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    self.medalliaPromise = resolve;
    
    // استرجاع البيانات المحفوظة
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults stringForKey:@"MedalliaUsername"] ?: @"";
    NSString *password = [defaults stringForKey:@"MedalliaPassword"] ?: @"";
    NSString *medalliaToken = [defaults stringForKey:@"MedalliaToken"] ?: @"default-medallia-token";
    NSString *surveyId = [defaults stringForKey:@"MedalliaSurveyId"] ?: @"default-survey-id";
    
    NSLog(@"Showing Medallia feedback form for user: %@", username);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentFeedbackViewControllerWithUsername:username
                                                password:password
                                           medalliaToken:medalliaToken
                                                surveyId:surveyId];
    });
    
    // إرسال إشارة أن النموذج جاهز
    NSDictionary *params = @{
        @"status": @"ready",
        @"message": @"Medallia feedback form is ready"
    };
    [self sendEventWithName:@"MedalliaFeedbackReady" body:params];
}

RCT_EXPORT_METHOD(injectUserData:(NSString *)username
                  password:(NSString *)password
                  medalliaToken:(NSString *)medalliaToken
                  surveyId:(NSString *)surveyId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    NSLog(@"Injecting user data: %@", username);
    
    // حفظ جميع البيانات في UserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:username forKey:@"MedalliaUsername"];
    [defaults setObject:password forKey:@"MedalliaPassword"];
    [defaults setObject:medalliaToken forKey:@"MedalliaToken"];
    [defaults setObject:surveyId forKey:@"MedalliaSurveyId"];
    [defaults synchronize];
    
    NSDictionary *params = @{
        @"username": username,
        @"status": @"injected"
    };
    [self sendEventWithName:@"UserDataInjected" body:params];
    
    resolve(@"User data injected successfully");
}

RCT_EXPORT_METHOD(handleNotification:(NSDictionary *)notificationData
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    NSString *type = notificationData[@"type"] ?: @"";
    NSString *username = notificationData[@"username"] ?: @"";
    NSString *password = notificationData[@"password"] ?: @"";
    NSString *medalliaToken = notificationData[@"medalliaToken"] ?: @"";
    NSString *surveyId = notificationData[@"surveyId"] ?: @"";
    
    NSLog(@"Handling notification of type: %@", type);
    
    if ([type isEqualToString:@"feedback_request"]) {
        // حفظ البيانات من الـ notification
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:username forKey:@"MedalliaUsername"];
        [defaults setObject:password forKey:@"MedalliaPassword"];
        [defaults setObject:medalliaToken forKey:@"MedalliaToken"];
        [defaults setObject:surveyId forKey:@"MedalliaSurveyId"];
        [defaults synchronize];
        
        // عرض نموذج التقييم تلقائياً
        [self showFeedbackForm:resolve rejecter:reject];
    } else {
        resolve(@"Notification handled but no action taken");
    }
}

RCT_EXPORT_METHOD(getStoredUserData:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults stringForKey:@"MedalliaUsername"] ?: @"";
    NSString *password = [defaults stringForKey:@"MedalliaPassword"] ?: @"";
    NSString *medalliaToken = [defaults stringForKey:@"MedalliaToken"] ?: @"";
    NSString *surveyId = [defaults stringForKey:@"MedalliaSurveyId"] ?: @"";
    
    NSDictionary *result = @{
        @"username": username,
        @"password": password,
        @"medalliaToken": medalliaToken,
        @"surveyId": surveyId
    };
    
    resolve(result);
}

- (void)presentFeedbackViewControllerWithUsername:(NSString *)username
                                         password:(NSString *)password
                                    medalliaToken:(NSString *)medalliaToken
                                         surveyId:(NSString *)surveyId {
    
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    // إنشاء ViewController مخصص للـ feedback
    UIViewController *feedbackVC = [[UIViewController alloc] init];
    feedbackVC.view.backgroundColor = [UIColor whiteColor];
    feedbackVC.title = @"تقييم الخدمة";
    
    // إنشاء التخطيط
    [self setupFeedbackUI:feedbackVC withUsername:username medalliaToken:medalliaToken surveyId:surveyId];
    
    // إنشاء Navigation Controller
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:feedbackVC];
    
    // إضافة زر الإغلاق
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(closeFeedbackForm)];
    feedbackVC.navigationItem.leftBarButtonItem = closeButton;
    
    // عرض النموذج
    [rootViewController presentViewController:navController animated:YES completion:nil];
}

- (void)setupFeedbackUI:(UIViewController *)viewController
           withUsername:(NSString *)username
          medalliaToken:(NSString *)medalliaToken
               surveyId:(NSString *)surveyId {
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [viewController.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];
    
    // عنوان النموذج
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"تقييم الخدمة";
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:titleLabel];
    
    // معلومات المستخدم
    UILabel *userLabel = [[UILabel alloc] init];
    userLabel.text = [NSString stringWithFormat:@"المستخدم: %@", username];
    userLabel.font = [UIFont systemFontOfSize:16];
    userLabel.textColor = [UIColor grayColor];
    userLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:userLabel];
    
    // حقل التقييم
    UILabel *ratingLabel = [[UILabel alloc] init];
    ratingLabel.text = @"التقييم (1-5):";
    ratingLabel.font = [UIFont systemFontOfSize:16];
    ratingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:ratingLabel];
    
    UITextField *ratingTextField = [[UITextField alloc] init];
    ratingTextField.placeholder = @"أدخل تقييمك من 1 إلى 5";
    ratingTextField.keyboardType = UIKeyboardTypeNumberPad;
    ratingTextField.borderStyle = UITextBorderStyleRoundedRect;
    ratingTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:ratingTextField];
    
    // حقل التعليق
    UILabel *feedbackLabel = [[UILabel alloc] init];
    feedbackLabel.text = @"التعليق:";
    feedbackLabel.font = [UIFont systemFontOfSize:16];
    feedbackLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:feedbackLabel];
    
    UITextView *feedbackTextView = [[UITextView alloc] init];
    feedbackTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    feedbackTextView.layer.borderWidth = 1.0;
    feedbackTextView.layer.cornerRadius = 5.0;
    feedbackTextView.font = [UIFont systemFontOfSize:16];
    feedbackTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:feedbackTextView];
    
    // أزرار التحكم
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:@"إلغاء" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cancelButton.backgroundColor = [UIColor redColor];
    cancelButton.layer.cornerRadius = 8;
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(handleCancel) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:cancelButton];
    
    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [submitButton setTitle:@"إرسال" forState:UIControlStateNormal];
    [submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    submitButton.backgroundColor = [UIColor systemBlueColor];
    submitButton.layer.cornerRadius = 8;
    submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [submitButton addTarget:self action:@selector(handleSubmit:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:submitButton];
    
    // إعداد الـ Constraints
    [NSLayoutConstraint activateConstraints:@[
        // ScrollView constraints
        [scrollView.topAnchor constraintEqualToAnchor:viewController.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:viewController.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:viewController.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:viewController.view.bottomAnchor],
        
        // ContentView constraints
        [contentView.topAnchor constraintEqualToAnchor:scrollView.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor],
        
        // Title constraints
        [titleLabel.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:20],
        [titleLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [titleLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        
        // User label constraints
        [userLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:20],
        [userLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [userLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        
        // Rating label constraints
        [ratingLabel.topAnchor constraintEqualToAnchor:userLabel.bottomAnchor constant:20],
        [ratingLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [ratingLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        
        // Rating text field constraints
        [ratingTextField.topAnchor constraintEqualToAnchor:ratingLabel.bottomAnchor constant:10],
        [ratingTextField.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [ratingTextField.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [ratingTextField.heightAnchor constraintEqualToConstant:44],
        
        // Feedback label constraints
        [feedbackLabel.topAnchor constraintEqualToAnchor:ratingTextField.bottomAnchor constant:20],
        [feedbackLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [feedbackLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        
        // Feedback text view constraints
        [feedbackTextView.topAnchor constraintEqualToAnchor:feedbackLabel.bottomAnchor constant:10],
        [feedbackTextView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [feedbackTextView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [feedbackTextView.heightAnchor constraintEqualToConstant:120],
        
        // Cancel button constraints
        [cancelButton.topAnchor constraintEqualToAnchor:feedbackTextView.bottomAnchor constant:30],
        [cancelButton.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [cancelButton.widthAnchor constraintEqualToConstant:100],
        [cancelButton.heightAnchor constraintEqualToConstant:44],
        
        // Submit button constraints
        [submitButton.topAnchor constraintEqualToAnchor:feedbackTextView.bottomAnchor constant:30],
        [submitButton.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [submitButton.widthAnchor constraintEqualToConstant:100],
        [submitButton.heightAnchor constraintEqualToConstant:44],
        
        // Content view bottom constraint
        [contentView.bottomAnchor constraintEqualToAnchor:submitButton.bottomAnchor constant:20]
    ]];
    
    // حفظ المراجع للاستخدام لاحقاً
    objc_setAssociatedObject(viewController, @"ratingTextField", ratingTextField, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(viewController, @"feedbackTextView", feedbackTextView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)handleSubmit:(UIButton *)sender {
    UIViewController *presentedVC = [UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController;
    UITextField *ratingTextField = objc_getAssociatedObject(presentedVC, @"ratingTextField");
    UITextView *feedbackTextView = objc_getAssociatedObject(presentedVC, @"feedbackTextView");
    
    NSString *rating = ratingTextField.text;
    NSString *feedback = feedbackTextView.text;
    
    if (rating.length == 0) {
        [self showAlert:@"خطأ" message:@"يرجى إدخال التقييم"];
        return;
    }
    
    int ratingValue = [rating intValue];
    if (ratingValue < 1 || ratingValue > 5) {
        [self showAlert:@"خطأ" message:@"التقييم يجب أن يكون بين 1 و 5"];
        return;
    }
    
    // إنشاء بيانات النموذج
    NSDictionary *formData = @{
        @"rating": @(ratingValue),
        @"feedback": feedback ?: @"",
        @"timestamp": @([[NSDate date] timeIntervalSince1970] * 1000)
    };
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:formData options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSLog(@"Form submitted with data: %@", jsonString);
    
    // إرسال النتيجة
    NSDictionary *params = @{
        @"formData": jsonString,
        @"action": @"submit"
    };
    [self sendEventWithName:@"MedalliaFormAction" body:params];
    
    [presentedVC dismissViewControllerAnimated:YES completion:^{
        if (self.medalliaPromise) {
            self.medalliaPromise(@"Form submitted successfully");
            self.medalliaPromise = nil;
        }
    }];
}

- (void)handleCancel {
    UIViewController *presentedVC = [UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController;
    
    NSDictionary *params = @{
        @"action": @"cancel"
    };
    [self sendEventWithName:@"MedalliaFormAction" body:params];
    
    [presentedVC dismissViewControllerAnimated:YES completion:^{
        if (self.medalliaPromise) {
            self.medalliaPromise(@"Form cancelled");
            self.medalliaPromise = nil;
        }
    }];
}

- (void)closeFeedbackForm {
    [self handleCancel];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"موافق"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];
    
    UIViewController *rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

@end
