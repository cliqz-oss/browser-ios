//
//  ActionViewController.m
//  Open In Cliqz
//
//  Created by Tim Palade on 7/13/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ActionViewController ()
@property(strong,nonatomic) NSURL *urlToOpen;
@end

@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL shouldBreak = NO;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                    if(url) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self openLink:url.absoluteString];
                        }];
                    }
                }];
                
                shouldBreak = YES;
            }
            
            if (shouldBreak) {
                break;
            }
        }
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)openLink:(NSString*)link {
    
    NSExtensionContext* context = self.extensionContext;
    NSString *url_string = [NSString stringWithFormat:@"cliqz://?url=%@",link];
    [context openURL:[NSURL URLWithString:url_string] completionHandler:^(BOOL success) {
        //NSLog(@"completion handler");
    }];
    
    UIResponder *responder = (UIResponder*)self;
    
    while(responder) {
        if ([responder respondsToSelector: @selector(openURL:)]) {
            [responder performSelector: @selector(openURL:) withObject: [NSURL URLWithString:url_string]];
            [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
        }
        responder = [responder nextResponder];
    }
    
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
