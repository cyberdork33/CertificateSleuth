//
//  AppDelegate.m
//  CertificateFinder
//
//  Created by cyberdork33@gmail.com on 5/14/12.
//

#import "AppDelegate.h"
#import <Security/Security.h>
#import <LDAPWrapper/LDAPConnectionManager.h>
#import <LDAPWrapper/LDAPEntry.h>

@interface AppDelegate ()

/* CLASS PROPERTIES */
@property (strong) NSArray *tableRows;
@property BOOL searching;

@end

@implementation AppDelegate

/* CLASS PROPERTIES */
@synthesize tableRows = _tableRows;
@synthesize searching = _searching;

/* INTERFACE OUTLETS */
@synthesize window = _window;
@synthesize certificateView = _certificateView;
@synthesize tableView = _tableView;
@synthesize statusMessage = _statusMessage;
@synthesize progressIndicator = _progressIndicator;
@synthesize sendMailButton = _sendMailButton;
@synthesize keychainButton = _keychainButton;

/* APPLICATION LIFECYCLE */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Setup and register userDefaults as well as the default userDefaults
    NSString *pathname = [[NSBundle mainBundle] pathForResource:@"defaultDefaults" ofType:@"plist"];
    NSDictionary *defaultDefaults = [NSDictionary dictionaryWithContentsOfFile:pathname];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDefaults];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultDefaults];

    // Setup interface initial conditions
    self.certificateView.displayDetails = YES;
    self.certificateView.displayTrust = YES;
    self.certificateView.hidden = YES;
    self.keychainButton.enabled = NO;
    self.sendMailButton.enabled = NO;
    self.statusMessage.objectValue = nil;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // Save any user-made changes to preferences
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/* INTERFACE ACTIONS */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (IBAction)search:(NSSearchField *)sender {

    // Prevent unneeded hits on the server.
    if (sender.stringValue.length > 2) {

        // Spin the progress indicator
        [self.progressIndicator performSelectorOnMainThread:@selector(startAnimation:)
                                                 withObject:self
                                              waitUntilDone:YES];

        // Get value from search box and reformat for valid ldap filter
        NSString *searchString = [NSString stringWithFormat:@"(cn=*%@*)",sender.stringValue];

        // attributes to retrieve in ldap query
        NSArray *attributes = [[NSArray alloc] initWithObjects:
                               @"userCertificate;binary",
                               @"cn",
                               @"mail",
                               nil];

        // Make LDAP object
        NSString *serverHostname = [[NSUserDefaults standardUserDefaults] objectForKey:@"ldapServer"];
        LDAPConnectionManager *ldap = [[LDAPConnectionManager alloc] initWithhost:serverHostname];

        // Perform Search
        NSString *searchBase = [[NSUserDefaults standardUserDefaults] objectForKey:@"ldapSearchBase"];
        NSArray *searchResult = [ldap searchLDAPBase: searchBase
                                             timeout:30
                                              filter:searchString
                                          attributes:attributes];
      if (ldap.errorEncountered) {

        // Display error message
        NSAlert *noResultAlert = [[NSAlert alloc] init];
        [noResultAlert addButtonWithTitle:@"OK"];
        noResultAlert.messageText = @"LDAP Error about Search Result:";
        noResultAlert.informativeText = ldap.lastLDAPError;
        noResultAlert.alertStyle = NSWarningAlertStyle;
        [noResultAlert runModal];

        // clear error
        [ldap clearError];

      } else {
        self.tableRows = searchResult;
      }

        // Sort all the results data by the names.
        //NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"Name" ascending:YES];
        //[self.tableRows sortUsingDescriptors:[NSArray arrayWithObject:sd]];

        // Redraw the table
        [self.tableView performSelectorOnMainThread:@selector(reloadData)
                                         withObject:nil
                                      waitUntilDone:YES];

        // Let the user know the operation is complete and waiting for further input.
        [self.progressIndicator performSelectorOnMainThread:@selector(stopAnimation:)
                                                 withObject:self
                                              waitUntilDone:YES];

        // Attempt to auto update the certificate view when the search changes.
        [self updateCertificateView];
    }
}

- (IBAction)setDefaultPreferences:(NSButton *)sender {

    // Set the preferences back to the defaultDefaults
    [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:sender];
}

- (IBAction)addCertificateToKeychain:(NSButton *)sender {

    // Add the certificate to the keychain
    OSStatus status = SecCertificateAddToKeychain(self.certificateView.certificate, NULL);
    if (status == noErr) {
        // Notify user that the certificate was added
        self.statusMessage.stringValue = @"Cert Added";
    } else if (status == errSecDuplicateItem) {
        self.statusMessage.stringValue = @"Already Added";
    } else {
        NSString *information = [NSString stringWithFormat:@"The certificate cannot be added to the keychain.  Error %d", status];

        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        alert.messageText = @"Can't Add Certificate";
        alert.informativeText = information;
        alert.alertStyle = NSWarningAlertStyle;
        [alert runModal];
        return;
    }
}

- (IBAction)emailSelectedUser:(NSButton *)sender {

    // Add the selected user's certificate to the keychain

    // Create new message to the user with the address from the certificate
    //TODO
    LDAPEntry *entry = [self.tableRows objectAtIndex:self.tableView.selectedRow];
    NSNumber *defaultEmailNumber = [NSNumber numberWithLong:entry.defaultEmailEntry];

    if (defaultEmailNumber != nil) {
        [self addCertificateToKeychain:sender];
        NSString *emailAddress = emailAddress
            = [entry.userCertificate.emailAddresses objectAtIndex:entry.defaultEmailEntry];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", emailAddress]];
        if (url != nil) {
            [[NSWorkspace sharedWorkspace] openURL:url];
        } else {
            self.statusMessage.stringValue = @"Invalid Email Address.";
        }

    }
}

/* NSTableViewDelegate ACTIONS */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    //NSLog(@"Rows to Display: %lu", self.tableRows.count);
    return self.tableRows.count;
}

- (void)tableView:(NSTableView *)tableView
  willDisplayCell:(id)cell
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row {

    LDAPEntry *entry = [self.tableRows objectAtIndex:row];

    NSTableHeaderCell *header = tableColumn.headerCell;
    if ([header.stringValue isEqualToString:@"Email"]) {

        NSPopUpButtonCell *theCell = cell;
        theCell.arrowPosition = NSPopUpNoArrow;
        // Users have several email addresses
        // Make a menu to select one.
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@"foo"];
        //NSArray *addrs = entry.mail;

        // Should do this with certificate emails?
        for (NSString *email in entry.mail) {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:email
                                                          action:NULL
                                                   keyEquivalent:@""];
            [menu addItem:item];
        }

        [theCell setMenu:menu];


        if (entry.mail.count > 0) {
            theCell.state = NSOnState;
            theCell.arrowPosition = NSPopUpArrowAtBottom;
            [theCell selectItemAtIndex:entry.defaultEmailEntry];
        }

    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {

    self.statusMessage.objectValue = nil;
    [self updateCertificateView];

}

- (void) updateCertificateView {
  if (self.tableView.selectedRow == -1) {

    NSLog(@"Nothing Selected?");
    self.certificateView.hidden = YES;
    self.keychainButton.enabled = NO;
    self.sendMailButton.enabled = NO;
    self.certificateView.policies = nil;
    self.certificateView.certificate = NULL;

  } else {

    LDAPEntry *entry = [self.tableRows objectAtIndex:self.tableView.selectedRow];
    NSLog(@"Row %ld selected.", self.tableView.selectedRow);

    if (entry.userCertificate.userCertificateData) {

      self.certificateView.certificate = entry.userCertificate.userCertificateRef;
      self.certificateView.hidden = NO;
      self.keychainButton.enabled = YES;
      self.sendMailButton.enabled = YES;
      self.certificateView.policies = nil;


    } else {

      self.certificateView.hidden = YES;
      self.keychainButton.enabled = NO;
      self.sendMailButton.enabled = NO;
      self.certificateView.policies = nil;
      self.certificateView.certificate = NULL;

    }
  }
}

/* NSTableViewDataSource METHODS*/
- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
                      row:(NSInteger)rowIndex {

    // Get a named pointer to the data row for this table row
    LDAPEntry *entry = [self.tableRows objectAtIndex:rowIndex];
    // Which column of the table are we in?
    NSTableHeaderCell *header = aTableColumn.headerCell;

    if ([header.stringValue isEqualToString:@"Name"]) {

        // What to put in the name cell
        return entry.cn;

    } else if ([header.stringValue isEqualToString:@"Certificate?"]) {

        return (entry.hasCertificate ? @"YES" : @"NO");

    } else {
        // All other cases (email cell is handled by
        //- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:NSTableColumn *)tableColumn row:(NSInteger)row
        return nil;
    }
}

- (void)tableView:(NSTableView *)tableView
   setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row {

    LDAPEntry *entry = [self.tableRows objectAtIndex:row];
    NSNumber *newValue = object;
    entry.defaultEmailEntry = newValue.integerValue;

}
// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/TableView/SortingTableViews/SortingTableViews.html
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    NSLog(@"Sort Descriptors Changed.");
    NSLog(@"%@", tableView.sortDescriptors);

    // Sort all the results data by the names.
    NSMutableArray *tempArray = self.tableRows.mutableCopy;
    [tempArray sortUsingDescriptors:self.tableView.sortDescriptors];
    self.tableRows = tempArray;

    [self.tableView reloadData];

}
@end
