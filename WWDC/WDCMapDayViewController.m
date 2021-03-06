//
//  WDCMapDayViewController.m
//  
//
//  Created by Genady Okrain on 5/18/14.
//
//

#import "WDCMapDayViewController.h"
#import "WDCParty.h"
#import "WDCPartyTableViewController.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import <objc/runtime.h>
#import "WDCParties.h"
#import <SDCloudUserDefaults/SDCloudUserDefaults.h>
@import MapKit;

@interface MKPointAnnotation (WDCPointAnnotation)

@property (strong, nonatomic) WDCParty *party;

@end


static const char kPartyKey;

@implementation MKPointAnnotation (WDCPointAnnotation)

- (WDCParty *)party
{
    return objc_getAssociatedObject(self, &kPartyKey);
}

- (void)setParty:(WDCParty *)party
{
    objc_setAssociatedObject(self, &kPartyKey, party, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface WDCMapDayViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation WDCMapDayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // hide back text
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];

    // Google
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"WDCMapDayViewController"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];

    self.title = [((WDCParty *)[self.parties lastObject]) date];

    self.mapView.delegate = self;

    [self refreshMap];
    [self.mapView showAnnotations:self.mapView.annotations animated:NO];
    self.mapView.camera.altitude *= 2;

    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:SDCloudValueUpdatedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if ([[note userInfo] objectForKey:@"going"] != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf refreshMap];
            });
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self refreshMap];
}

- (void)refreshMap
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    for (WDCParty *party in self.parties) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = CLLocationCoordinate2DMake([party.latitude floatValue], [party.longitude floatValue]);
        annotation.title = party.title;
        annotation.subtitle = [party hours];
        annotation.party = party;
        [self.mapView addAnnotation:annotation];
    }
}

#pragma - mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }

    MKPinAnnotationView *v = nil;
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        v = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"party"];

        if (!v) {
            v = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"party"];
        }
        v.pinColor = MKPinAnnotationColorPurple;
        if ([SDCloudUserDefaults objectForKey:@"going"] != nil) {
            if ([[SDCloudUserDefaults objectForKey:@"going"] isKindOfClass:[NSArray class]]) {
                if ([[SDCloudUserDefaults objectForKey:@"going"] indexOfObject:((MKPointAnnotation *)annotation).party.objectId] != NSNotFound) {
                    v.pinColor = MKPinAnnotationColorGreen;
                }
            }
        }
        v.canShowCallout = YES;
        v.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    return v;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"party" sender:view.annotation];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"party"]) {
        if ([sender isKindOfClass:[MKPointAnnotation class]]) {
            WDCPartyTableViewController *destController = segue.destinationViewController;
            WDCParty *party = ((MKPointAnnotation *)sender).party;
            destController.party = party;
        }
    }
}

@end
