//
//  IMAppDelegate.m
//  IMGlobalCacheDBClient
//
//  Created by Ian McCullough on 4/7/13.
//  Copyright (c) 2013 Ian McCullough. All rights reserved.
//

#import "IMAppDelegate.h"
#import <vis.h>

@interface IMAppDelegate () <NSTextFieldDelegate>

@property (nonatomic, readwrite, copy) NSString* APIKey;

@property (nonatomic, readonly) NSURL* baseURL;
@property (nonatomic, readonly) NSURL* APIBaseURL;

@property (nonatomic, readwrite, assign) NSUInteger requestsInFlight;

@property (nonatomic, readwrite, copy) NSArray* manufacturers;
@property (nonatomic, readwrite, copy) NSString* selectedManufacturerKey;
@property (nonatomic, readwrite, copy) NSArray* deviceTypes;
@property (nonatomic, readwrite, copy) NSString* selectedDeviceTypeKey;
@property (nonatomic, readwrite, copy) NSArray* codesets;
@property (nonatomic, readwrite, copy) NSString* selectedCodesetKey;
@property (nonatomic, readwrite, copy) NSArray* codes;
@property (nonatomic, readwrite, copy) NSIndexSet* selectedCodeIndexes;

- (void)updateManufacturers;
- (void)updateDeviceTypes;
- (void)updateCodesets;
- (void)updateCodes;

- (IBAction)saveCodes:(id)sender;
- (IBAction)goToAPIKeyWebsite:(id)sender;

@end

static void * const IMAppDelegateAPIKeyKVOContext = (void*)&IMAppDelegateAPIKeyKVOContext;
static void * const IMAppDelegateSelectedManufacturerKVOContext = (void*)&IMAppDelegateSelectedManufacturerKVOContext;
static void * const IMAppDelegateSelectedDeviceTypeKVOContext = (void*)&IMAppDelegateSelectedDeviceTypeKVOContext;
static void * const IMAppDelegateSelectedCodesetKVOContext = (void*)&IMAppDelegateSelectedCodesetKVOContext;

@implementation IMAppDelegate

@synthesize requestsInFlight;

@synthesize manufacturers;
@synthesize selectedManufacturerKey;

@synthesize deviceTypes;
@synthesize selectedDeviceTypeKey;

@synthesize codesets;
@synthesize selectedCodesetKey;

@synthesize codes;
@synthesize selectedCodeIndexes;

- (void)dealloc
{
    [manufacturers release];
    [selectedManufacturerKey release];
    [deviceTypes release];
    [selectedDeviceTypeKey release];
    [codesets release];
    [selectedCodesetKey release];
    [codes release];
    [selectedCodeIndexes release];
    
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self addObserver: self forKeyPath: NSStringFromSelector(@selector(APIKey)) options: 0 context: IMAppDelegateAPIKeyKVOContext];
    [self addObserver: self forKeyPath: NSStringFromSelector(@selector(selectedManufacturerKey)) options: 0 context: IMAppDelegateSelectedManufacturerKVOContext];
    [self addObserver: self forKeyPath: NSStringFromSelector(@selector(selectedDeviceTypeKey)) options: 0 context: IMAppDelegateSelectedDeviceTypeKVOContext];
    [self addObserver: self forKeyPath: NSStringFromSelector(@selector(selectedCodesetKey)) options: 0 context: IMAppDelegateSelectedCodesetKVOContext];

    [self updateManufacturers];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (IMAppDelegateAPIKeyKVOContext == context)
    {
        [self updateManufacturers];
    }
    else if (IMAppDelegateSelectedManufacturerKVOContext == context)
    {
        [self updateDeviceTypes];
    }
    else if (IMAppDelegateSelectedDeviceTypeKVOContext == context)
    {
        [self updateCodesets];
    }
    else if (IMAppDelegateSelectedCodesetKVOContext == context)
    {
        [self updateCodes];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSString*)APIKey
{
    return [[NSUserDefaults standardUserDefaults] stringForKey: @"GlobalCacheAPIKey"];
}

- (void)setAPIKey:(NSString *)APIKey
{
    if (APIKey)
        [[NSUserDefaults standardUserDefaults] setObject: APIKey forKey:@"GlobalCacheAPIKey"];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"GlobalCacheAPIKey"];
    
    [NSObject cancelPreviousPerformRequestsWithTarget: [NSUserDefaults standardUserDefaults] selector: @selector(synchronize) object: nil];
    [[NSUserDefaults standardUserDefaults] performSelector: @selector(synchronize) withObject: nil afterDelay: 0.0];
}

- (NSURL *)baseURL
{
    NSURL* url = [NSURL URLWithString: @"http://irdatabase.globalcache.com/"];
    return url;
}

- (NSURL *)APIBaseURL
{
    NSURL* url = [[self.baseURL URLByAppendingPathComponent: @"api"] URLByAppendingPathComponent: @"v1"];
    url = [url URLByAppendingPathComponent: self.APIKey];
    return url;
}

- (void)updateManufacturers
{
    if (0 == self.APIKey.length)
        return;
    
    self.selectedManufacturerKey = nil;
    self.manufacturers = nil;
    self.selectedDeviceTypeKey = nil;
    self.deviceTypes = nil;
    self.selectedCodesetKey = nil;
    self.codesets = nil;
    self.codes = nil;
    
    NSURL* url = [self.APIBaseURL URLByAppendingPathComponent: @"manufacturers"];
    NSURLRequest* req = [NSURLRequest requestWithURL: url];
    
    self.requestsInFlight++;
    
    [NSURLConnection sendAsynchronousRequest: req queue: [NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSError* err = nil;
        id plist = [NSJSONSerialization JSONObjectWithData: data options: 0 error: &err];
        self.manufacturers = plist;
        self.requestsInFlight--;
    }];
}

- (void)updateDeviceTypes
{
    if (0 == self.APIKey.length)
        return;
    
    self.selectedDeviceTypeKey = nil;
    self.deviceTypes = nil;
    self.selectedCodesetKey = nil;
    self.codesets = nil;
    self.codes = nil;

    if (self.selectedManufacturerKey)
    {
        NSURL* url = [self.APIBaseURL URLByAppendingPathComponent: @"manufacturers"];
        url = [url URLByAppendingPathComponent: self.selectedManufacturerKey];
        url = [url URLByAppendingPathComponent: @"devicetypes"];
        NSURLRequest* req = [NSURLRequest requestWithURL: url];
        
        self.requestsInFlight++;
        
        [NSURLConnection sendAsynchronousRequest: req queue: [NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError* err = nil;
            id plist = [NSJSONSerialization JSONObjectWithData: data options: 0 error: &err];
            self.deviceTypes = plist;
            self.requestsInFlight--;
        }];
    }
}

- (void)updateCodesets
{
    if (0 == self.APIKey.length)
        return;
    
    self.selectedCodesetKey = nil;
    self.codesets = nil;
    self.codes = nil;

    if (self.selectedDeviceTypeKey)
    {
        NSURL* url = [self.APIBaseURL URLByAppendingPathComponent: @"manufacturers"];
        url = [url URLByAppendingPathComponent: self.selectedManufacturerKey];
        url = [url URLByAppendingPathComponent: @"devicetypes"];
        url = [url URLByAppendingPathComponent: self.selectedDeviceTypeKey];
        url = [url URLByAppendingPathComponent: @"codesets"];
        NSURLRequest* req = [NSURLRequest requestWithURL: url];
        
        self.requestsInFlight++;
        
        [NSURLConnection sendAsynchronousRequest: req queue: [NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError* err = nil;
            id plist = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &err];
            NSUInteger index = 0;
            for (NSMutableDictionary* dictionary in plist)
            {
                dictionary[@"UICodesetName"] = [NSString stringWithFormat: @"Codeset %lu (%@)", (unsigned long)index++, dictionary[@"Codeset"]];
            }
            self.codesets = plist;
            self.requestsInFlight--;
        }];
    }
}

- (void)updateCodes
{
    if (0 == self.APIKey.length)
        return;
    
    self.codes = nil;

    if (self.selectedCodesetKey)
    {
        NSURL* url = [self.APIBaseURL URLByAppendingPathComponent: @"manufacturers"];
        url = [url URLByAppendingPathComponent: self.selectedManufacturerKey];
        url = [url URLByAppendingPathComponent: @"devicetypes"];
        url = [url URLByAppendingPathComponent: self.selectedDeviceTypeKey];
        url = [url URLByAppendingPathComponent: @"codesets"];
        url = [url URLByAppendingPathComponent: self.selectedCodesetKey];

        NSURLRequest* req = [NSURLRequest requestWithURL: url];
        
        self.requestsInFlight++;
        
        [NSURLConnection sendAsynchronousRequest: req queue: [NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError* err = nil;
            id plist = [NSJSONSerialization JSONObjectWithData: data options: 0 error: &err];
            self.codes = plist;
            self.requestsInFlight--;
        }];
    }
}

- (NSString*)fileName
{
    NSString* manufacturerName = nil;
    for (NSDictionary* d in self.manufacturers)
    {
        if ([d[@"Key"] isEqual: self.selectedManufacturerKey])
        {
            manufacturerName = d[@"Manufacturer"] ?: self.selectedManufacturerKey;
            manufacturerName = [manufacturerName stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            break;
        }
    }
    
    NSString* deviceType = nil;
    for (NSDictionary* d in self.deviceTypes)
    {
        if ([d[@"Key"] isEqual: self.selectedDeviceTypeKey])
        {
            deviceType = d[@"DeviceType"] ?: self.selectedDeviceTypeKey;
            deviceType = [deviceType stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            break;
        }
    }

    NSString* codeset = nil;
    for (NSDictionary* d in self.codesets)
    {
        if ([d[@"Key"] isEqual: self.selectedCodesetKey])
        {
            codeset = d[@"Codeset"] ?: self.selectedCodesetKey;
            codeset = [codeset stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            break;
        }
    }

    NSMutableString* string = [NSMutableString string];

    if (manufacturerName.length)
    {
        [string appendString: manufacturerName];
    }
    
    if (deviceType.length)
    {
        if (string.length) [string appendString: @"-"];
        [string appendString: deviceType];
    }
    
    if (codeset.length)
    {
        if (string.length) [string appendString: @"-"];
        [string appendString: codeset];
    }

    if (string.length)
    {
        return [string stringByAppendingPathExtension: @"json"];
    }

    return nil;
}



- (IBAction)saveCodes:(id)sender
{
    NSIndexSet* localSelectedCodeIndexes = self.selectedCodeIndexes;
    
    if (localSelectedCodeIndexes.count == 0)
    {
        localSelectedCodeIndexes = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, self.codes.count)];
    }

    NSArray* selectedCodes = [self.codes objectsAtIndexes: localSelectedCodeIndexes];
    
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject: selectedCodes options: NSJSONWritingPrettyPrinted error: &error];
    
    if (error)
    {
        [NSApp presentError: error];
    }
    else
    {
        NSSavePanel* savePanel = [NSSavePanel savePanel];
        
        savePanel.nameFieldStringValue = self.fileName;
        
        [savePanel beginSheetModalForWindow: self.window completionHandler:^(NSInteger result) {
            if (NSFileHandlingPanelOKButton == result)
            {
                NSURL* url = savePanel.URL;
                NSError* error = nil;
                if(![data writeToURL: url options: NSDataWritingAtomic error: &error])
                {
                    [NSApp presentError: error];
                }
            }
        }];
    }
}

- (IBAction)goToAPIKeyWebsite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: self.baseURL];
}

- (IBAction)copy:(id)sender
{
    NSMutableString* tabularText = [NSMutableString string];
    NSArray* selectedCodes = [self.codes objectsAtIndexes: self.selectedCodeIndexes];
    if (selectedCodes.count)
    {
        for (NSString* key in [selectedCodes.lastObject allKeys])
        {
            [tabularText appendFormat: @"%@\t", key];
        }
        [tabularText replaceCharactersInRange: NSMakeRange(tabularText.length - 1, 1) withString: @"\n"];
        
        for (NSDictionary* d in selectedCodes)
        {
            for (NSString* key in [d allKeys])
            {
                NSString* value = [d[key] description];
                NSMutableData* data = [NSMutableData dataWithLength: 4 * value.length + 1];
                strvis(data.mutableBytes, [value UTF8String], VIS_TAB | VIS_NL | VIS_CSTYLE);
                [tabularText appendFormat: @"%s\t", data.bytes];
            }
            [tabularText replaceCharactersInRange: NSMakeRange(tabularText.length - 1, 1) withString: @"\n"];
        }
        
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];

        // Text
        [pasteboard setString: tabularText forType: NSPasteboardTypeTabularText];

        // JSON
        NSError* error = nil;
        NSData* data = [NSJSONSerialization dataWithJSONObject: selectedCodes options:NSJSONWritingPrettyPrinted error: &error];
        NSString* jsonString = [[[NSString alloc] initWithBytes: data.bytes length: data.length encoding: NSUTF8StringEncoding] autorelease];
        
        [pasteboard setString: jsonString forType: NSPasteboardTypeString];
        [pasteboard setString: jsonString forType: @"public.json"];
    }
}

@end




