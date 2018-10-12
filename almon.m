// almon.m
// version 1.0

#import <Cocoa/Cocoa.h>
#import <stdio.h>
#include <signal.h>

@interface almon: NSObject {}
-(id) init;
-(void) launchedApp: (NSNotification*) notification;
@end

@implementation almon
-(id) init {
  NSNotificationCenter * notify
    = [[NSWorkspace sharedWorkspace] notificationCenter];

  [notify addObserver: self
          selector:    @selector(launchedApp:)
          name:        @"NSWorkspaceWillLaunchApplicationNotification"
          object:      nil
  ];
  fprintf(stderr,"Listening...\n");
  [[NSRunLoop currentRunLoop] run];
  fprintf(stderr,"Stopping...\n");
  return self;
}

-(void) launchedApp: (NSNotification*) notification {
  NSDictionary *userInfo = [notification userInfo]; // read full application launch info
  NSString* AppPID = [userInfo objectForKey:@"NSApplicationProcessIdentifier"]; // parse for AppPID
  int killPID = [AppPID intValue]; // define integer from NSString
  kill((killPID), SIGSTOP); // interrupt app launch
  NSString* AppPath = [userInfo objectForKey:@"NSApplicationPath"]; // read application path
  NSString* AppBundleID = [userInfo objectForKey:@"NSApplicationBundleIdentifier"]; // read BundleID
  NSString* AppName = [userInfo objectForKey:@"NSApplicationName"]; // read AppName
  NSLog(@":::%@:::%@:::%@:::%@", AppPID, AppPath, AppBundleID, AppName); // output to stderr
}
@end

int main( int argc, char ** argv) {
  [[almon alloc] init];
  return 0;
}
// build: gcc -Wall almon.m -o almon -lobjc -framework Cocoa
// run: ./almon
