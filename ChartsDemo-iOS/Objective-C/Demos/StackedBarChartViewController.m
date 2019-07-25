//
//  StackedBarChartViewController.m
//  ChartsDemo
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

#import "StackedBarChartViewController.h"
#import "ChartsDemo_iOS-Swift.h"

@interface StackedBarChartViewController () <ChartViewDelegate>

@property (nonatomic, strong) IBOutlet BarChartView *chartView;
@property (nonatomic, strong) IBOutlet UISlider *sliderX;
@property (nonatomic, strong) IBOutlet UISlider *sliderY;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextX;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextY;

@end

@implementation StackedBarChartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Stacked Bar Chart";
    
    self.options = @[
                     @{@"key": @"toggleValues", @"label": @"Toggle Values"},
                     @{@"key": @"toggleIcons", @"label": @"Toggle Icons"},
                     @{@"key": @"toggleHighlight", @"label": @"Toggle Highlight"},
                     @{@"key": @"animateX", @"label": @"Animate X"},
                     @{@"key": @"animateY", @"label": @"Animate Y"},
                     @{@"key": @"animateXY", @"label": @"Animate XY"},
                     @{@"key": @"saveToGallery", @"label": @"Save to Camera Roll"},
                     @{@"key": @"togglePinchZoom", @"label": @"Toggle PinchZoom"},
                     @{@"key": @"toggleAutoScaleMinMax", @"label": @"Toggle auto scale min/max"},
                     @{@"key": @"toggleData", @"label": @"Toggle Data"},
                     @{@"key": @"toggleBarBorders", @"label": @"Show Bar Borders"},
                    ];
    
    _chartView.delegate = self;
    _chartView.legend.enabled = NO;
    _chartView.leftAxis.enabled = NO;
    _chartView.noDataText = @"暂无骑行数据";
    _chartView.scaleYEnabled = NO;
    _chartView.doubleTapToZoomEnabled = NO;
    _chartView.highlightFullBarEnabled = YES;

    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionBottom;
    xAxis.labelFont = [UIFont systemFontOfSize:12];
    xAxis.labelTextColor = UIColor.lightGrayColor;
    xAxis.drawGridLinesEnabled = NO;
    xAxis.axisLineColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.4];
    xAxis.labelCount = 7;
    xAxis.granularity = 1;
    xAxis.spaceMin = xAxis.spaceMax = 0.75;
    
    ChartYAxis *rightAxis = _chartView.rightAxis;
    rightAxis.labelFont = xAxis.labelFont;
    rightAxis.labelCount = 5;
    rightAxis.labelTextColor = xAxis.labelTextColor;
    rightAxis.axisLineDashLengths = @[@(2), @(2)];
    rightAxis.axisLineDashPhase = 2;
    rightAxis.gridLineDashLengths = rightAxis.axisLineDashLengths;
    rightAxis.axisMinimum = 0;
    rightAxis.gridColor = xAxis.axisLineColor;
    rightAxis.axisLineColor = xAxis.axisLineColor;
    NSNumberFormatter *rightAxisFormatter = NSNumberFormatter.new;
    rightAxisFormatter.multiplier = @(0.001);
    rightAxisFormatter.minimumFractionDigits = 0;
    rightAxisFormatter.maximumFractionDigits = 1;
    rightAxisFormatter.minimumIntegerDigits = 1;
    rightAxisFormatter.negativePrefix = nil;
    rightAxisFormatter.negativeSuffix = @"km";
    rightAxisFormatter.positiveSuffix = rightAxisFormatter.negativeSuffix;
    rightAxis.valueFormatter = [[ChartDefaultAxisValueFormatter alloc] initWithFormatter:rightAxisFormatter];
    
    ChartLegend *l = _chartView.legend;
    l.horizontalAlignment = ChartLegendHorizontalAlignmentRight;
    l.verticalAlignment = ChartLegendVerticalAlignmentBottom;
    l.orientation = ChartLegendOrientationHorizontal;
    l.drawInside = NO;
    l.form = ChartLegendFormSquare;
    l.formSize = 8.0;
    l.formToTextSpace = 4.0;
    l.xEntrySpace = 6.0;
    
    _sliderX.value = 6;
    _sliderY.value = 100.0;
    [self slidersValueChanged:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateChartData
{
    if (self.shouldHideData)
    {
        _chartView.data = nil;
        return;
    }
    
    [self setDataCount:_sliderX.value + 1 range:_sliderY.value];
}

- (void)setDataCount:(int)count range:(double)range
{
    NSMutableArray *yVals = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < count; i++)
    {
        double mult = (range + 1);
        double val1 = (double) (arc4random_uniform(mult) + mult / 3);
        double val2 = (double) (arc4random_uniform(mult) + mult / 3);
        
        [yVals addObject:[[BarChartDataEntry alloc] initWithX:i yValues:@[@(val1), @(val2)]]];
    }
    
    BarChartDataSet *set1 = nil;
    if (_chartView.data.dataSetCount > 0)
    {
        set1 = (BarChartDataSet *)_chartView.data.dataSets[0];
        set1.values = yVals;
        [_chartView.data notifyDataChanged];
        [_chartView notifyDataSetChanged];
    }
    else
    {
        set1 = [[BarChartDataSet alloc] initWithValues:yVals];
        
        set1.axisDependency = AxisDependencyRight;
        set1.cornerRadius = 3;
        set1.roundedCorners = UIRectCornerTopLeft|UIRectCornerTopRight;
        set1.drawValuesEnabled = NO;
        set1.highlightAlpha = 0;
        
        CGFloat alpha = 0.5;
        set1.barGradientColors = @[
  @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
  @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
  @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
  @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
  @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
  @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
  @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
  @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
  @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
  @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
  @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
  @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
  @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
  @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]]
  ];
        
        NSMutableArray *dataSets = [[NSMutableArray alloc] init];
        [dataSets addObject:set1];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.maximumFractionDigits = 1;
        formatter.negativeSuffix = @" $";
        formatter.positiveSuffix = @" $";
        
        BarChartData *data = [[BarChartData alloc] initWithDataSets:dataSets];
        data.barWidth = 0.5;
        
//        _chartView.fitBars = YES;
        _chartView.data = data;
    }
    
    _chartView.visibleXRangeMaximum = 7;
//    [_chartView moveViewToX:_chartView.chartXMax-7.25];
    
//    [_chartView highlightValueWithX:2 dataSetIndex:0 stackIndex:-1];
}

- (void)optionTapped:(NSString *)key
{
    [super handleOption:key forChartView:_chartView];
}

#pragma mark - Actions

- (IBAction)slidersValueChanged:(id)sender
{
    _sliderTextX.text = [@((int)_sliderX.value) stringValue];
    _sliderTextY.text = [@((int)_sliderY.value) stringValue];
    
    [self updateChartData];
}

#pragma mark - ChartViewDelegate

- (void)chartValueSelected:(ChartViewBase * __nonnull)chartView entry:(ChartDataEntry * __nonnull)entry highlight:(ChartHighlight * __nonnull)highlight
{
//    NSLog(@"chartValueSelected, stack-index %ld", (long)highlight.x);
//    
//    CGFloat alpha = 0.5;
//    NSMutableArray *arr = @[
//                            @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.yellowColor colorWithAlphaComponent:alpha], [UIColor.orangeColor colorWithAlphaComponent:alpha]],
//                            @[[UIColor.redColor colorWithAlphaComponent:alpha], [UIColor.purpleColor colorWithAlphaComponent:alpha]]
//                            ].mutableCopy;
//    [arr insertObjects:@[@[[UIColor.yellowColor colorWithAlphaComponent:1], [UIColor.orangeColor colorWithAlphaComponent:1]],
//                        @[[UIColor.redColor colorWithAlphaComponent:1], [UIColor.purpleColor colorWithAlphaComponent:1]]] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange((long)highlight.x*2, 2)]];
//    ((BarChartDataSet *)chartView.data.dataSets[0]).barGradientColors = arr;
//    [chartView notifyDataSetChanged];
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView
{
    NSLog(@"chartValueNothingSelected");
}

@end
