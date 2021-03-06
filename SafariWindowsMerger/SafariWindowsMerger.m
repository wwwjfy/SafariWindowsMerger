//
//  SafariWindowsMerger.m
//  SafariWindowsMerger
//
//  Created by Tony Wang on 4/28/14.
//  Copyright (c) 2014 Tony Wang. All rights reserved.
//

#import "SafariWindowsMerger.h"
#import <objc/message.h>

#define CHECK_WIN(win) \
if ([[win window] isMiniaturized]) { \
  return; \
}

void moveSrcToDest(id srcWin, id destWin) {
  CHECK_WIN(srcWin)
  CHECK_WIN(destWin)
  id tabViewItem = objc_msgSend(srcWin, @selector(selectedTab));
  NSInteger toIndex = [[[objc_msgSend(destWin, @selector(selectedTab)) tabView] tabViewItems] count];
  for (NSTabView *item in [[tabViewItem tabView] tabViewItems]) {
    objc_msgSend(destWin, @selector(moveTabFromOtherWindow:toIndex:andSelect:),
                 item, toIndex, NO);
    toIndex++;
  }
}

void moveSrcToNewWindowAfterSelected(id srcWin) {
  CHECK_WIN(srcWin)
  NSUInteger selectedIndex = (NSUInteger)objc_msgSend(srcWin, @selector(selectedTabIndex));
  id tabViewItem = objc_msgSend(srcWin, @selector(selectedTab));
  id tabViewItems = [[tabViewItem tabView] tabViewItems];
  id toMoveItems = [tabViewItems subarrayWithRange:NSMakeRange(selectedIndex, [tabViewItems count] - selectedIndex)];
  objc_msgSend(srcWin, @selector(_moveTabToNewWindow:), tabViewItem);
  if ([toMoveItems count] > 0) {
    NSUInteger destIndex = 0;
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
  CHECK_WIN(win)
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
  CHECK_WIN(win)
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
  CHECK_WIN(win)
  NSUInteger lastIndex = [[[objc_msgSend(win, @selector(selectedTab)) tabView] tabViewItems] count] - 1;
  objc_msgSend(win, @selector(selectTabAtIndex:), lastIndex);
}

void newTabAfterSelected(id win) {
  CHECK_WIN(win)
  NSUInteger selectedIndex = (NSUInteger)objc_msgSend(win, @selector(selectedTabIndex));
  objc_msgSend(win, @selector(createTabAtIndex:andSelect:), selectedIndex + 1, YES);
}

@implementation SafariWindowsMerger

+ (void)load {
  NSLog(@"SafariWindowsMerger installed");
  [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyUpMask
                                        handler:^NSEvent *(NSEvent *theEvent) {
                                          if (([theEvent modifierFlags] & NSControlKeyMask) &&
                                              ([theEvent modifierFlags] & NSShiftKeyMask) &&
                                              !([theEvent modifierFlags] & NSAlternateKeyMask) &&
                                              !([theEvent modifierFlags] & NSCommandKeyMask)) {
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
                                          } else if (!([theEvent modifierFlags] & NSControlKeyMask) &&
                                                     ([theEvent modifierFlags] & NSShiftKeyMask) &&
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
                                          } else if (!([theEvent modifierFlags] & NSControlKeyMask) &&
                                                     !([theEvent modifierFlags] & NSShiftKeyMask) &&
                                                     !([theEvent modifierFlags] & NSAlternateKeyMask) &&
                                                     ([theEvent modifierFlags] & NSCommandKeyMask)) {
                                            id win = [[NSApp orderedWindows][0] windowController];
                                            switch ([theEvent keyCode]) {
                                              case 25: // '9'
                                                goToLastTab(win);
                                                break;

                                              default:
                                                break;
                                            }
                                          } else if (!([theEvent modifierFlags] & NSControlKeyMask) &&
                                                     !([theEvent modifierFlags] & NSShiftKeyMask) &&
                                                     ([theEvent modifierFlags] & NSAlternateKeyMask) &&
                                                     ([theEvent modifierFlags] & NSCommandKeyMask)) {
                                            id win = [[NSApp orderedWindows][0] windowController];
                                            switch ([theEvent keyCode]) {
                                              case 17: // 't'
                                                newTabAfterSelected(win);
                                                break;

                                              default:
                                                break;
                                            }
                                          }
                                          return theEvent;
                                        }];
}

@end
