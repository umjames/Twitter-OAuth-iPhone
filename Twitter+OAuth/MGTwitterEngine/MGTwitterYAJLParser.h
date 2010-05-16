//
//  MGTwitterYAJLParser.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"

#include <yajl/yajl_parse.h>

#import "MGTwitterParserDelegate.h"
#import "MGTwitterEngineDelegate.h"

@interface MJStackElement : NSObject
{
	id				_value;
	MJStackElement*	_parent;
}

@property (nonatomic, retain) id				value;
@property (nonatomic, retain) MJStackElement*	parent;

+ (MJStackElement*)stackElementWithValue: (id)value parent: (MJStackElement*)parent;

- (id)initWithValue: (id)value parent: (MJStackElement*)parent;

@end

@interface MJStack : NSObject
{
	NSMutableArray*	_stack;
}

- (void)push: (MJStackElement*)obj;
- (MJStackElement*)pop;
- (MJStackElement*)top;

- (MJStackElement*)findTopmostStackElementWithValueOfClass: (Class)cls;

- (NSUInteger)size;

@end

@interface MGTwitterYAJLParser : NSObject {
	__weak NSObject <MGTwitterParserDelegate> *delegate; // weak ref
	NSString *identifier;
	MGTwitterRequestType requestType;
	MGTwitterResponseType responseType;
	NSURL *URL;
	NSData *json;
	NSMutableArray *parsedObjects;
	MGTwitterEngineDeliveryOptions deliveryOptions;
	MJStack*	_parserStack;
	
	yajl_handle _handle;
}

+ (id)parserWithJSON:(NSData *)theJSON
	delegate:(NSObject *)theDelegate
	connectionIdentifier:(NSString *)identifier
	requestType:(MGTwitterRequestType)reqType
	responseType:(MGTwitterResponseType)respType
	URL:(NSURL *)URL
	deliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions;
- (id)initWithJSON:(NSData *)theJSON
	delegate:(NSObject *)theDelegate 
	connectionIdentifier:(NSString *)identifier
	requestType:(MGTwitterRequestType)reqType 
	responseType:(MGTwitterResponseType)respType
	URL:(NSURL *)URL
	deliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions;

// subclass utilities
- (void)addValue:(id)value forKey:(NSString *)key;
- (void)addValue:(id)value forKey:(NSString *)key;
- (void)startDictionaryWithKey:(NSString *)key;
- (void)endDictionary;
- (void)startArrayWithKey:(NSString *)key;
- (void)endArray;
- (void)dictionaryKeyChanged: (NSString*)key;
- (NSString*)currentKey;

// delegate callbacks
- (void)_parsingDidEnd;
- (void)_parsingErrorOccurred:(NSError *)parseError;
- (void)_parsedObject:(NSDictionary *)dictionary;


@end
