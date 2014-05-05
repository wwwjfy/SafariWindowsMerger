//
//  SafariWindowsMerger.m
//  SafariWindowsMerger
//
//  Created by Tony Wang on 4/28/14.
//  Copyright (c) 2014 Tony Wang. All rights reserved.
//

#import "SafariWindowsMerger.h"
#import <objc/message.h>

BOOL isWindowNotAvailable(id win) {
  if ([[win window] isMiniaturized]) {
    return YES;
  } else {
    return NO;
  }
}

void moveSrcToDest(id srcWin, id destWin) {
  if (isWindowNotAvailable(srcWin) || isWindowNotAvailable(destWin)) {
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
  if (isWindowNotAvailable(srcWin)) {
    return;
  }
  NSUInteger selectedIndex = (NSUInteger)objc_msgSend(srcWin, @selector(selectedTabIndex));
  id tabViewItem = objc_msgSend(srcWin, @selector(selectedTab));
  objc_msgSend(srcWin, @selector(_moveTabToNewWindow:), tabViewItem);
  id tabViewItems = [[tabViewItem tabView] tabViewItems];
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

// The index count is a bit tricky: the toIndex should be when the current tab has not been moved.
void moveTabLeftward(id win) {
  if (isWindowNotAvailable(win)) {
    return;
  }
  id tabViewItem = objc_msgSend(win, @selector(selectedTab));
  NSUInteger selectedIndex = (NSUInteger)objc_msgSend(win, @selector(selectedTabIndex));
  if (selectedIndex == 0) {
    id tabViewItems = [[tabViewItem tabView] tabViewItems];
    selectedIndex = [tabViewItems count];
  } else {
    selectedIndex--;
  }
  objc_msgSend(win, @selector(moveTab:toIndex:), tabViewItem, selectedIndex);
}

void moveTabRightward(id win) {
  if (isWindowNotAvailable(win)) {
    return;
  }
  id tabViewItem = objc_msgSend(win, @selector(selectedTab));
  NSUInteger selectedIndex = (NSUInteger)objc_msgSend(win, @selector(selectedTabIndex));
  id tabViewItems = [[tabViewItem tabView] tabViewItems];
  if (selectedIndex == ([tabViewItems count] - 1)) {
    selectedIndex = 0;
  } else {
    selectedIndex += 2;
  }
  objc_msgSend(win, @selector(moveTab:toIndex:), tabViewItem, selectedIndex);
}

void goToLastTab(id win) {
  if (isWindowNotAvailable(win)) {
    return;
  }
  NSUInteger lastIndex = [[[objc_msgSend(win, @selector(selectedTab)) tabView] tabViewItems] count] - 1;
  objc_msgSend(win, @selector(_selectTabAtIndex:), lastIndex);
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
                                          } else if (([theEvent modifierFlags] & NSShiftKeyMask) &&
                                                     ([theEvent modifierFlags] & NSAlternateKeyMask) &&
                                                     ([theEvent modifierFlags] & NSCommandKeyMask)) {
                                            id win = [[NSApp orderedWindows][0] windowController];
                                            switch ([theEvent keyCode]) {
                                              case 33: // '['
                                                moveTabLeftward(win);
                                                break;

                                              case 30: // ']'
                                                moveTabRightward(win);
                                                break;

                                              default:
                                                break;
                                            }
                                          } else if (([theEvent modifierFlags] & NSCommandKeyMask)) {
                                            id win = [[NSApp orderedWindows][0] windowController];
                                            switch ([theEvent keyCode]) {
                                              case 25: // '9'
                                                goToLastTab(win);
                                                break;

                                              default:
                                                break;
                                            }
                                          }
                                          return theEvent;
                                        }];
}

@end
