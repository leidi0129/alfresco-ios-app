//
//  LocationManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface LocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, readonly, assign, getter = isTrackingLocation) BOOL trackingLocation;

+ (LocationManager *)sharedManager;
- (CLLocationCoordinate2D)currentLocationCoordinates;
- (BOOL)usersLocationAuthorisation;
- (void)startLocationUpdates;
- (void)stopLocationUpdates;

@end
