//
//  BeanBrowserViewController.m
//  
//
//  Created by Scott Cheezem on 10/15/15.
//
//

#import "BeanBrowserViewController.h"
#import <PTDBeanManager.h>


@interface BeanBrowserViewController() <PTDBeanManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)PTDBeanManager *beanManager;
@property(strong) PTDBean *currentBean;
@property(nonatomic, retain)NSMutableOrderedSet *setOfBeans;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end


@implementation BeanBrowserViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.setOfBeans = [[NSMutableOrderedSet alloc]init];
    self.beanManager = [[PTDBeanManager alloc]initWithDelegate:self];
    
}
  
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    // call will fail if we don't give Bluetooth a bit of time to spin up
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSError *error;
        if ( self.currentBean != nil ) {
            [self.beanManager disconnectBean:self.currentBean error:nil];
            self.currentBean = nil;
        }
        self.setOfBeans = [[NSMutableOrderedSet alloc]init];
        [self.tableView reloadData];
        
        [self.beanManager startScanningForBeans_error:&error];
        if ( error != nil ) {
            NSLog(@"Error scanning for beans: %@", error );
        }
        
    });
}


-(void)beanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error{
    [self.setOfBeans addObject:bean];
    [self.tableView reloadData];
}

-(void)beanManager:(PTDBeanManager *)beanManager didConnectBean:(PTDBean *)bean error:(NSError *)error{
    //dissmiss the modal here, and set the bean for communication on the main viewcontroller
    self.audioViewController.lightControllerBean = bean;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)beanManagerDidUpdateState:(PTDBeanManager *)beanManager{
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  self.setOfBeans.count;
}


-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *beanCell = [tableView dequeueReusableCellWithIdentifier:@"beanCell" forIndexPath:indexPath];
    PTDBean *aBean = self.setOfBeans.array[indexPath.row];
    beanCell.textLabel.text = aBean.name;
    beanCell.detailTextLabel.text = [NSString stringWithFormat:@"rssi:%i", aBean.RSSI.intValue];
    return beanCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    PTDBean *selectedBean = (PTDBean*)self.setOfBeans.array[indexPath.row];
    NSError *error;
    [self.beanManager connectToBean:selectedBean error:&error];
    if (error) {
        NSLog(@"error connecting:%@", error);
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    
}

- (IBAction)dissmissAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
