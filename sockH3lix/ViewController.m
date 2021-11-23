//
//  ViewController.m
//  d0ubleH3lix
//
//  Created by tihmstar on 10.12.17.
//  Copyright © 2017 tihmstar. All rights reserved.
//

#import "ViewController.h"
#include "jailbreak.h"
#include <sys/utsname.h>
#include <time.h>
#include <errno.h>
#include <sys/sysctl.h>


#define postProgress(prg) [[NSNotificationCenter defaultCenter] postNotificationName: @"JB" object:nil userInfo:@{@"JBProgress": prg}]
extern int (*dsystem)(const char *);
int mccall(uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4);
pid_t mpd;

@interface ViewController ()

@end

double uptime(){
    struct timeval boottime;
    size_t len = sizeof(boottime);
    int mib[2] = { CTL_KERN, KERN_BOOTTIME };
    if( sysctl(mib, 2, &boottime, &len, NULL, 0) < 0 )
    {
        return -1.0;
    }
    time_t bsec = boottime.tv_sec, csec = time(NULL);

    return difftime(csec, bsec);
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgressFromNotification:) name:@"JB" object:nil];

    struct utsname name;
    uname(&name);

        if (strstr(name.version, "MarijuanARM")){
            self.statusLabel.text = @"";
            [self.gobtn setTitle:@"  run uicache  " forState:UIControlStateNormal];
        }else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"]){
            [self.gobtn setTitle:@"  Kickstart  " forState:UIControlStateNormal];
        }
}

-(void)updateProgressFromNotification:(id)sender{

    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSString *prog=[sender userInfo][@"JBProgress"];
        NSLog(@"Progress: %@",prog);
        self.statusLabel.text = prog;
        self.statusLabel.hidden = NO;
        self.gobtn.hidden = YES;
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)go:(id)sender {
    self.gobtn.enabled = false;
    postProgress(@"looking up offset");
    dispatch_async(jailbreak_queue , ^{

        struct utsname name;
        uname(&name);
        if (strstr(name.version, "MarijuanARM")){
            postProgress(@"running uicache");
            //int r = jailbreak_system("(bash -c \"rm /var/mobile/Library/Cydia/metadata.cb0;/usr/bin/uicache;killall backboardd\") &");
            int r = jailbreak_system("(bash -c \"/usr/bin/uicache;killall backboardd\") &");
            if (r!=0) {
                postProgress(@"uicache failed!");
            }else{
                postProgress(@"uicache done!");
            }

            dispatch_sync(dispatch_get_main_queue(), ^(void){
                [self.gobtn setTitle:@"done uicache" forState:UIControlStateNormal];
            });
        }else{

            postProgress(@"running exploit");
            usleep(USEC_PER_SEC/100);
            if (!jailbreak()){
                dispatch_sync(dispatch_get_main_queue(), ^(void){
                    [self.gobtn setTitle:@"done jb" forState:UIControlStateNormal];
                });
            }
        }
    });
}
@end
