//
//  AppDelegate.h
//  CertificateFinder
//
//  Created by cyberdork33@gmail.com on 5/14/12.
//

#import <Cocoa/Cocoa.h>
#import <SecurityInterface/SFCertificateView.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource>

/* INTERFACE OUTLETS */
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet SFCertificateView *certificateView;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *statusMessage;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *sendMailButton;
@property (weak) IBOutlet NSButton *keychainButton;

/* INTERFACE ACTIONS */
- (IBAction)search:(NSSearchField *)sender;
- (IBAction)setDefaultPreferences:(NSButton *)sender;
- (IBAction)addCertificateToKeychain:(NSButton *)sender;
- (IBAction)emailSelectedUser:(NSButton *)sender;

@end
