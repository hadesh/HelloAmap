//
//  ViewController.m
//  HelloAmap
//
//  Created by xiaoming han on 14-10-21.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import "CustomAnnotationView.h"

#define APIKey      @"95ed2da3e9f4ece6319afbc437fc0b01"

@interface ViewController ()<MAMapViewDelegate, AMapSearchDelegate, UITableViewDataSource, UITableViewDelegate>
{
    MAMapView *_mapView;
    AMapSearchAPI *_search;
    
    CLLocation *_currentLocation;
    
    UITableView *_tableView;
    NSArray *_pois;
    
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initMapView];
    [self initSearch];
    [self initTableView];
    [self initControls];
    [self initAttributes];
}

- (void)initMapView
{
    [MAMapServices sharedServices].apiKey = APIKey;
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    
    _mapView.delegate = self;
    
//    [self.view addSubview:_mapView];
    
    _mapView.showsUserLocation = YES;
}

- (void)initSearch
{
    _search = [[AMapSearchAPI alloc] initWithSearchKey:APIKey Delegate:self];
}

- (void)initControls
{
    //
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    searchButton.frame = CGRectMake(22, CGRectGetHeight(self.view.bounds) - 80, 40, 40);
    searchButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    searchButton.backgroundColor = [UIColor blackColor];
    [searchButton setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    
    [searchButton addTarget:self action:@selector(searchAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:searchButton];
    
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(80, CGRectGetHeight(self.view.bounds) - 80, 220, 40)];
    bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 2, 200, 20)];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:14];
    _titleLabel.text = @"xxx";
    
    [bgView addSubview:_titleLabel];
    
    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 22, 200, 18)];
    _subtitleLabel.textColor = [UIColor lightGrayColor];
    _subtitleLabel.font = [UIFont boldSystemFontOfSize:12];
    _subtitleLabel.text = @"xxxxxxxx";
    
    [bgView addSubview:_subtitleLabel];
    
    [self.view addSubview:bgView];
}

- (void)initAttributes
{
    _pois = nil;
}

- (void)initTableView
{
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self.view addSubview:_tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Helpers

- (void)searchAction
{
    if (_currentLocation == nil || _search == nil)
    {
        NSLog(@"search failed");
        return;
    }
    
    AMapPlaceSearchRequest *request = [[AMapPlaceSearchRequest alloc] init];
    request.searchType = AMapSearchType_PlaceAround;
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    
    request.keywords = @"餐饮";
    
    [_search AMapPlaceSearch:request];
    
    [self reGeoAction];
}

- (void)reGeoAction
{
    if (_currentLocation)
    {
        AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc] init];
        
        request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
        
        [_search AMapReGoecodeSearch:request];
    }
}

#pragma mark - AMapSearchDelegate

- (void)searchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"request :%@, error :%@", request, error);
}

- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    NSLog(@"response :%@", response);
    
    NSString *title = response.regeocode.addressComponent.city;
    if (title.length == 0)
    {
        // 直辖市的city为空，取province
        title = response.regeocode.addressComponent.province;
    }
    
    // 更新我的位置title
    _titleLabel.text = title;
    _subtitleLabel.text = response.regeocode.formattedAddress;
}

- (void)onPlaceSearchDone:(AMapPlaceSearchRequest *)request response:(AMapPlaceSearchResponse *)response
{
    
    if (response.pois.count > 0)
    {
        _pois = response.pois;
        
        [_tableView reloadData];
    }
}

#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
//    NSLog(@"userLocation: %@", userLocation.location);
    if (updatingLocation)
    {
        _currentLocation = [userLocation.location copy];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    AMapPOI *poi = _pois[indexPath.row];
    
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    
    return cell;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _pois.count;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 为点击的poi点添加标注
    AMapPOI *poi = _pois[indexPath.row];
    
    NSLog(@"poi :%@", poi);
}

@end
