//
//  SafariWindowsMerger.m
//  SafariWindowsMerger
//
//  Created by Tony Wang on 4/28/14.
//  Copyright (c) 2014 Tony Wang. All rights reserved.
//

#import "SafariWindowsMerger.h"
#import <objc/message.h>

void moveSrcToDest(id srcWin, id destWin) {
  if ([[srcWin window] isMiniaturized] || [[destWin window] isMiniaturized]) {
    return;
  }
  id tabViewItem = objc_msgSend(srcWin, @selector(selectedTab));
  NSInteger toIndex = [[[objc_msgSend(destWin, @selector(selectedTab)) tabView] tabViewItems] count];
  for (NSTabView *item in [[tabViewItem tabView] tabViewItems]) {
    objc_msgSend(destWin, @selector(moveTabFromOtherWindow:toIndex:andSelect:),
                 item, toIndex, NO);
    toIndex++;
  }
}

void moveSrcToNewWindowAfterSelected(id srcWin) {
  if ([[srcWin window] isMiniaturized]) {
    return;
  }
  NSUInteger selectedIndex = (NSUInteger)objc_msgSend(srcWin, @selector(selectedTabIndex));
  id tabViewItem = objc_msgSend(srcWin, @selector(selectedTab));
  objc_msgSend(srcWin, @selector(_moveTabToNewWindow:), tabViewItem);
  id tabViewItems = [[objc_msgSend(srcWin, @selector(selectedTab)) tabView] tabViewItems];
  id toMoveItems = [tabViewItems subarrayWithRange:NSMakeRange(selectedIndex, [tabViewItems count] - selectedIndex)];
  if ([toMoveItems count] > 0) {
    NSUInteger destIndex = 1;
    id destWin = [[NSApp orderedWindows][0] windowController];
    for (id item in toMoveItems) {
      objc_msgSend(destWin, @selector(moveTabFromOtherWindow:toIndex:andSelect:),
                   item, destIndex, NO);
      destIndex++;
    }
  }
}

@implementation SafariWindowsMerger

+ (void)load {
  NSLog(@"SafariWindowsMerger installed");
  [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyUpMask
                                        handler:^NSEvent *(NSEvent *theEvent) {
                                          if (([theEvent modifierFlags] & NSControlKeyMask) &&
                                              ([theEvent modifierFlags] & NSShiftKeyMask)) {
                                            switch ([theEvent keyCode]) {
                                              case 46: // 'M'
                                              {
                                                id destWin = [[NSApp orderedWindows][0] windowController];
                                                id srcWin = [[NSApp orderedWindows][1] windowController];
                                                moveSrcToDest(srcWin, destWin);
                                              }
                                                break;

                                              case 45: // 'N'
                                              {
                                                id srcWin = [[NSApp orderedWindows][0] windowController];
                                                moveSrcToNewWindowAfterSelected(srcWin);
                                              }
                                                break;

                                              default:
                                                break;
                                            }
                                          }
                                          return theEvent;
                                        }];
}

@end
