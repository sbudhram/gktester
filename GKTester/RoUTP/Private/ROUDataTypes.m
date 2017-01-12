//
//  ROUDataTypes.m
//  RoUTPTests
//
//  Created by Yan Rabovik on 30.06.13.
//  Copyright (c) 2013 Yan Rabovik. All rights reserved.
//

#import "ROUDataTypes.h"
#import "ROUPrivate.h"

#if !__has_feature(objc_arc)
#error This code needs ARC. Use compiler option -fobjc-arc
#endif

#pragma mark - Structures -
ROUChunkHeader ROUChunkHeaderMake(ROUChunkType type, uint8_t flags, uint16_t length, NSString *sender, NSArray<NSString*> *recipients){
    ROUChunkHeader header;
    header.type = type;
    header.flags = flags;
    header.length = length;
    
    //Checks on senders/recipients
    NSCAssert(sender != nil, @"Sender must be specified");
    NSCAssert(sender.length <= ROU_PLAYER_SIZE, @"GKCloudPlayerID must be less than %d characters <sender>", ROU_PLAYER_SIZE);

    NSCAssert(recipients != nil || recipients.count == 0, @"At least one recipient must be specified");
    NSCAssert(recipients.count < 4, @"No more than 3 recipients allowed");
    for (NSString *recipient in recipients) {
        NSCAssert(recipient.length <= ROU_PLAYER_SIZE, @"GKCloudPlayerID must be less than %d characters <recipient>", ROU_PLAYER_SIZE);
    }

    //Fill in sender/receivers
    const char *sndr = [sender UTF8String];
    strncpy(header.sender, sndr, sender.length);

    const char *rcpt = [recipients[0] UTF8String];
    strncpy(header.receiver0, rcpt, recipients[0].length);
    
    if (recipients.count > 1) {
        rcpt = [recipients[1] UTF8String];
        strncpy(header.receiver1, rcpt, recipients[1].length);
    }
    
    if (recipients.count > 2) {
        rcpt = [recipients[2] UTF8String];
        strncpy(header.receiver2, rcpt, recipients[2].length);
    }
    
    return header;
}

ROUChunkHeader ROUChunkHeaderAddFlag(ROUChunkHeader header, uint8_t flag){
    ROUChunkHeader newHeader = header;
    newHeader.flags = header.flags | flag;
    return newHeader;
}

ROUAckSegmentShift ROUAckSegmentShiftMake(uint16_t start, uint16_t end){
    ROUAckSegmentShift segment;
    segment.start = start;
    segment.end = end;
    return segment;
}

bool ROUAckSegmentShiftsEqual(ROUAckSegmentShift segmentShift1,
                              ROUAckSegmentShift segmentShift2)
{
    return  segmentShift1.start == segmentShift2.start &&
            segmentShift1.end   == segmentShift2.end;
}

#pragma mark - Classes -
#pragma mark Common chunks
@interface ROUChunk (){
    @protected
    NSData *_encodedChunk;
}
@property (nonatomic,strong) NSData *encodedChunk;
@property (nonatomic,readwrite) ROUChunkHeader header;
@end

@implementation ROUChunk
+(id)chunkWithEncodedChunk:(NSData *)encodedChunk{
    ROUThrow(@"+[%@ %@] not implemented",
             NSStringFromClass(self),
             NSStringFromSelector(_cmd));
    return nil;
}
-(NSData *)encodedChunk{
    ROUThrow(@"-[%@ %@] not implemented",
             NSStringFromClass([self class]),
             NSStringFromSelector(_cmd));
    return nil;
}
@end

#pragma mark Data chunk
@interface ROUDataChunk ()
@property (nonatomic,readwrite) uint32_t tsn;
@property (nonatomic,strong) NSData *data;
@end

@implementation ROUDataChunk
+(id)chunkWithEncodedChunk:(NSData *)encodedChunk{
    if (encodedChunk.length <= ROU_HEADER_TSN_SIZE) {
        ROUThrow(@"Encoded data chunk is too short");
    }
    ROUDataChunk *chunk = [self new];
    chunk.encodedChunk = encodedChunk;
    
    ROUChunkHeader header;
    [encodedChunk getBytes:&header range:NSMakeRange(0, ROU_HEADER_SIZE)];
    chunk.header = header;

    uint32_t tsn;
    [encodedChunk getBytes:&tsn range:NSMakeRange(ROU_HEADER_SIZE, sizeof(uint32_t))];
    chunk.tsn = tsn;
    
    return chunk;
}
+(id)chunkWithData:(NSData *)data TSN:(uint32_t)tsn sender:(NSString*)sender recipients:(NSArray<NSString*>*)recipients {
    if (data.length > UINT16_MAX-8) {
        ROUThrow(@"Data in chunk may not be longer than %lu bytes",UINT16_MAX - ROU_HEADER_TSN_SIZE);
    }
    ROUDataChunk *chunk = [self new];
    chunk.header = ROUChunkHeaderMake(ROUChunkTypeData, 0, data.length + ROU_HEADER_TSN_SIZE, sender, recipients);
    chunk.tsn = tsn;
    chunk.data = data;
    return chunk;
}

+(id)unreliableChunkWithData:(NSData *)data sender:(NSString*)sender recipients:(NSArray<NSString*>*)recipients {
    if (data.length > UINT16_MAX-ROU_HEADER_TSN_SIZE) {
        ROUThrow(@"Data in chunk may not be longer than %lu bytes", UINT16_MAX - ROU_HEADER_TSN_SIZE);
    }
    ROUDataChunk *chunk = [self new];
    chunk.header = ROUChunkHeaderMake(ROUChunkUnreliable, 0, data.length + ROU_HEADER_TSN_SIZE, sender, recipients);
    chunk.data = data;
    return chunk;
}


-(NSData *)encodedChunk{
    if (nil != self->_encodedChunk) {
        return _encodedChunk;
    }
    NSAssert(nil != self.data, @"");
    NSMutableData *chunk = [NSMutableData dataWithCapacity:ROU_HEADER_TSN_SIZE + self.data.length];
    ROUChunkHeader header = self.header;
    [chunk appendBytes:&header length:ROU_HEADER_SIZE];
    [chunk appendBytes:&_tsn length:sizeof(_tsn)];
    [chunk appendData:_data];
    return chunk;
}
-(NSData *)data{
    if (nil != _data) {
        return _data;
    }
    NSAssert(nil != self.encodedChunk, @"");
    return [self.encodedChunk
            subdataWithRange:NSMakeRange(ROU_HEADER_TSN_SIZE, self.encodedChunk.length-ROU_HEADER_TSN_SIZE)];
}
@end

@implementation ROUSndDataChunk
@end

#pragma mark Ack chunk
@interface ROUAckChunk ()
@property (nonatomic,readwrite) uint32_t tsn;
@end

@implementation ROUAckChunk{
    NSMutableIndexSet *_segmentsIndexSet;
}

+(id)chunkWithTSN:(uint32_t)tsn{
    ROUAckChunk *chunk = [self new];
    chunk.tsn = tsn;
    
    return chunk;
}

+(id)chunkWithEncodedChunk:(NSData *)encodedChunk{
    if (encodedChunk.length < ROU_HEADER_TSN_SIZE) {
        ROUThrow(@"Encoded ack chunk is too short");
    }
    ROUAckChunk *chunk = [self new];
    chunk.encodedChunk = encodedChunk;
    
    ROUChunkHeader header;
    [encodedChunk getBytes:&header range:NSMakeRange(0, ROU_HEADER_SIZE)];
    
    uint32_t tsn;
    [encodedChunk getBytes:&tsn range:NSMakeRange(ROU_HEADER_SIZE, sizeof(u_int32_t))];
    chunk.tsn = tsn;
    
    if (header.flags & ROUAckFlagsHasSegments) {
        NSUInteger currentPosition = ROU_HEADER_TSN_SIZE;
        while (currentPosition + 4 <= header.length) {
            ROUAckSegmentShift segmentShift;
            [encodedChunk getBytes:&segmentShift range:NSMakeRange(currentPosition, 4)];
            NSRange range =
                NSMakeRange(tsn+segmentShift.start,
                            segmentShift.end - segmentShift.start + 1);
            [chunk->_segmentsIndexSet
                addIndexesInRange:range];
            currentPosition += 4;
        }
    }
    
    return chunk;
}

-(id)init{
    self = [super init];
    if (nil == self) return nil;
	_segmentsIndexSet = [NSMutableIndexSet indexSet];
	return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"<%@ %p> header.type=%u header.flags=%u header.length=%u TSN=%u segments=%@ encodedChunk=%@",
            NSStringFromClass([self class]),
            self,
            self.header.type,
            self.header.flags,
            self.header.length,
            _tsn,
            _segmentsIndexSet,
            _encodedChunk];
}

-(void)addSegmentFrom:(uint32_t)fromTSN to:(uint32_t)toTSN{
    NSAssert(fromTSN > self.tsn + 1,
             @"tsn=%u fromTSN=%u toTSN=%u",
             self.tsn,
             fromTSN,
             toTSN);
    NSAssert(toTSN >= fromTSN,
             @"tsn=%u fromTSN=%u toTSN=%u",
             self.tsn,
             fromTSN,
             toTSN);
    [self addSegmentWithRange:NSMakeRange(fromTSN, toTSN-fromTSN+1)];
}

-(void)addSegmentWithRange:(NSRange)range{
    NSAssert(range.location > self.tsn + 1,
             @"tsn=%u %@",
             self.tsn,
             NSStringFromRange(range));
    NSAssert(range.length > 0,
             @"tsn=%u %@",
             self.tsn,
             NSStringFromRange(range));
    _encodedChunk = nil;
    [_segmentsIndexSet addIndexesInRange:range];
}


-(NSIndexSet *)segmentsIndexSet{
    return _segmentsIndexSet;
}

-(NSIndexSet *)missedIndexSet{
    if (_segmentsIndexSet.firstIndex <= self.tsn + 1) {
        ROUThrow(@"In ack chunkTSN should be lower than segments.\n%@",self);
    }
    NSMutableIndexSet *missed = [NSMutableIndexSet indexSet];
    __block NSUInteger start = self.tsn + 1;
    [_segmentsIndexSet enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        NSUInteger end = range.location - 1;
        [missed addIndexesInRange:NSMakeRange(start, end-start+1)];
        start = range.length + range.location;
    }];
    return missed;
}

-(NSData *)encodedChunk{
    if (nil != _encodedChunk) {
        return _encodedChunk;
    }
    ROUChunkHeader header = self.header;
    NSMutableData *encodedChunk = [NSMutableData dataWithCapacity:header.length];
    [encodedChunk appendBytes:&header length:ROU_HEADER_SIZE];
    [encodedChunk appendBytes:&_tsn length:sizeof(_tsn)];
    NSAssert(4 == sizeof(ROUAckSegmentShift), @"ROUAckSegmentShift size should be 4");
    [_segmentsIndexSet enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        ROUAckSegmentShift segment =
            ROUAckSegmentShiftMake(range.location-_tsn,
                                   range.location-_tsn+range.length-1);
        [encodedChunk appendBytes:&segment length:4];
    }];
    return encodedChunk;
}

@end

#pragma mark - Categories -
@implementation NSValue (ROUAckSegmentShift)

+(NSValue *)rou_valueWithAckSegmentShift:(ROUAckSegmentShift)segment{
    return [NSValue valueWithBytes:&segment objCType:@encode(ROUAckSegmentShift)];
}

-(ROUAckSegmentShift)rou_ackSegmentShift{
    ROUAckSegmentShift segment;
    [self getValue:&segment];
    return segment;
}

@end
