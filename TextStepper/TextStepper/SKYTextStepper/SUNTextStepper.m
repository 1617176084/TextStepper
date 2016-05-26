//
//  SUNTextStepper.m
//  SUNTextStepper
//
//  Created by sky on 15/4/24.
//  Copyright (c) 2015年 wang. All rights reserved.
//

#import "SUNTextStepper.h"

static const float kButtonWidth = 44.0f;

@interface SUNTextStepper ()

@property(nonatomic, strong, readonly) UIButton *plusButton;
@property(nonatomic, strong, readonly) UIButton *minusButton;
@property(nonatomic, strong, readonly) UITextField *textField;

- (NSString *)getPlaceholderText;
- (void)didChangeTextField;
@end

@implementation SUNTextStepper

TextStepperChangeType _longTapLoopType;

#pragma mark initialization
- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  self.numDecimals = 0;
  _stepInterval = 1.0f;
  _minimum = 0.0f;
  _maximum = INFINITY;

  _buttonWidth = kButtonWidth;
  _editableText = NO;

  self.clipsToBounds = YES;
  [self setBorderWidth:1.0f];
  [self setCornerRadius:3.0];

  _textField = [[UITextField alloc] init];
  self.textField.textAlignment = NSTextAlignmentCenter;
  self.textField.layer.borderWidth = 1.0f;
  self.textField.placeholder = [self getPlaceholderText];
  [self.textField setKeyboardType:UIKeyboardTypeDecimalPad];
  [self.textField addTarget:self
                     action:@selector(didChangeTextField)
           forControlEvents:UIControlEventEditingChanged];
  [self.textField addTarget:self
                     action:@selector(didEditingDidEnd)
           forControlEvents:UIControlEventEditingDidEnd];

  self.textField.enabled = _editableText;
  [self addSubview:self.textField];

  _plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.plusButton setTitle:@"+" forState:UIControlStateNormal];
  [self.plusButton addTarget:self
                      action:@selector(incrementButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
  [self.plusButton
             addTarget:self
                action:@selector(didBeginPlusLongTap)
      forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
  [self.plusButton
             addTarget:self
                action:@selector(didEndLongTap)
      forControlEvents:UIControlEventTouchUpInside |
                       UIControlEventTouchUpOutside |
                       UIControlEventTouchCancel | UIControlEventTouchDragExit];

  [self addSubview:self.plusButton];

  _minusButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.minusButton setTitle:@"−" forState:UIControlStateNormal];
  [self.minusButton addTarget:self
                       action:@selector(decrementButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];
  [self.minusButton
             addTarget:self
                action:@selector(didBeginMinusLongTap)
      forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
  [self.minusButton
             addTarget:self
                action:@selector(didEndLongTap)
      forControlEvents:UIControlEventTouchUpInside |
                       UIControlEventTouchUpOutside |
                       UIControlEventTouchCancel | UIControlEventTouchDragExit];
  [self addSubview:self.minusButton];

  UIColor *defaultColor = [UIColor colorWithRed:(79 / 255.0)
                                          green:(161 / 255.0)
                                           blue:(210 / 255.0)
                                          alpha:1.0];
  [self setBorderColor:defaultColor];
  [self setTextColor:defaultColor];
  [self setButtonTextColor:defaultColor forState:UIControlStateNormal];

  [self setTextFont:[UIFont fontWithName:@"Avernir-Roman" size:14.0f]];
  [self setButtonFont:[UIFont fontWithName:@"Avenir-Black" size:24.0f]];
}

#pragma mark render
- (void)layoutSubviews {
  CGFloat width = self.bounds.size.width;
  CGFloat height = self.bounds.size.height;

  self.textField.frame =
      CGRectMake(self.buttonWidth, 0, width - (self.buttonWidth * 2), height);
  self.plusButton.frame =
      CGRectMake(width - self.buttonWidth, 0, self.buttonWidth, height);
  self.minusButton.frame = CGRectMake(0, 0, self.buttonWidth, height);
}

- (CGSize)sizeThatFits:(CGSize)size {
  if (CGSizeEqualToSize(size, CGSizeZero)) {
    // if CGSizeZero, return ideal size
    CGSize textFieldSize = [self.textField sizeThatFits:size];
    return CGSizeMake(textFieldSize.width + (self.buttonWidth * 2),
                      textFieldSize.height);
  }
  return size;
}

#pragma mark view customization
#pragma mark setter
- (void)setEditableText:(BOOL)editableText {
  _editableText = editableText;
  self.textField.enabled = editableText;
}

- (void)setBorderColor:(UIColor *)color {
  self.layer.borderColor = color.CGColor;
  self.textField.layer.borderColor = color.CGColor;
}

- (void)setBorderWidth:(CGFloat)width {
  self.layer.borderWidth = width;
}

- (void)setCornerRadius:(CGFloat)radius {
  self.layer.cornerRadius = radius;
}

- (void)setTextColor:(UIColor *)color {
  self.textField.textColor = color;
}

- (void)setTextFont:(UIFont *)font {
  self.textField.font = font;
}

- (void)setButtonTextColorNormal:(UIColor *)color {
  [self setButtonTextColor:color forState:UIControlStateNormal];
}
- (void)setButtonTextColor:(UIColor *)color forState:(UIControlState)state {
  [self.plusButton setTitleColor:color forState:state];
  [self.minusButton setTitleColor:color forState:state];
}

- (void)setButtonFont:(UIFont *)font {
  self.plusButton.titleLabel.font = font;
  self.minusButton.titleLabel.font = font;
}

- (float)currentValue {
  return [self.textField.text floatValue];
}

- (void)setCurrentValue:(float)currentValue {
  self.textField.text = [NSString
      stringWithFormat:
          [@"%.Xf"
              stringByReplacingOccurrencesOfString:@"X"
                                        withString:[NSString
                                                       stringWithFormat:
                                                           @"%d",
                                                           self.numDecimals]],
          currentValue];
}

- (void)setChangeType:(TextStepperChangeType)changeType {
  _changeType = changeType;

  if (self.changeType == TextStepperChangeTypeNegative) {
    if (self.currentValue > self.minimum) {
      self.currentValue -= self.stepInterval;
    } else {
      self.currentValue = self.minimum;
    }
  } else {
    if (self.currentValue < self.maximum) {
      self.currentValue += self.stepInterval;
    } else {
      self.currentValue = self.maximum;
    }
  }
}

- (void)setNumDecimals:(int)numDecimals {
  _numDecimals = numDecimals;
  if (_numDecimals < 0) {
    _numDecimals = 0;
  }

  self.textField.placeholder =
      [self getPlaceholderText]; // to correctly display the decimal number when
                                 // deleting all charaters

  self.currentValue = self.currentValue; // to re-display it correctly
}

- (NSString *)getPlaceholderText {
  NSMutableString *lstrDato = [NSMutableString stringWithString:@"0"];
  for (int i = 0; i < self.numDecimals; i++) {
    if (lstrDato.length == 1) // is first time
    {
      [lstrDato appendString:@"."];
    }
    [lstrDato appendString:@"0"];
  }
  return lstrDato;
}

- (void)didEditingDidEnd {
  [self didChangeTextField];
}
- (void)didChangeTextField {
  self.currentValue = self.currentValue;
  if (self.currentValue < self.minimum)
    self.currentValue = self.minimum;

  if (self.currentValue > self.maximum)
    self.currentValue = self.maximum;

  [self sendActionsForControlEvents:UIControlEventValueChanged];

  if (self.valueChangedCallback) {
    self.valueChangedCallback(self, self.currentValue);
  }
}

#pragma mark button event handler

#pragma mark Plus Button Events
- (void)incrementButtonTapped:(id)sender {
  [self.textField resignFirstResponder];
  self.changeType = TextStepperChangeTypePositive;

  [self sendActionsForControlEvents:UIControlEventValueChanged];

  if (self.valueChangedCallback) {
    self.valueChangedCallback(self, self.currentValue);
  }
}

- (void)didBeginPlusLongTap {
  [self.textField resignFirstResponder];
  _longTapLoopType = TextStepperChangeTypePositive;
  [NSObject
      cancelPreviousPerformRequestsWithTarget:self
                                     selector:@selector(backgroundLongTapLoop)
                                       object:nil];
  [self performSelector:@selector(backgroundLongTapLoop)
             withObject:nil
             afterDelay:0.5];
}

#pragma mark Minus Button Events
- (void)decrementButtonTapped:(id)sender {
  [self.textField resignFirstResponder];
  self.changeType = TextStepperChangeTypeNegative;

  [self sendActionsForControlEvents:UIControlEventValueChanged];

  if (self.valueChangedCallback) {
    self.valueChangedCallback(self, self.currentValue);
  }
}

- (void)didBeginMinusLongTap {
  [self.textField resignFirstResponder];
  _longTapLoopType = TextStepperChangeTypeNegative;
  [NSObject
      cancelPreviousPerformRequestsWithTarget:self
                                     selector:@selector(backgroundLongTapLoop)
                                       object:nil];
  [self performSelector:@selector(backgroundLongTapLoop)
             withObject:nil
             afterDelay:0.5];
}

#pragma mark Long Tap Loop

- (void)didEndLongTap {
  [self.textField resignFirstResponder];
  [NSObject
      cancelPreviousPerformRequestsWithTarget:self
                                     selector:@selector(backgroundLongTapLoop)
                                       object:nil];
}

- (void)backgroundLongTapLoop {
  [self.textField resignFirstResponder];
  [self performSelectorOnMainThread:@selector(longTapLoop)
                         withObject:nil
                      waitUntilDone:YES];
  [self performSelector:@selector(backgroundLongTapLoop)
             withObject:nil
             afterDelay:0.1];
}

- (void)longTapLoop {

  self.changeType = _longTapLoopType;

  [self sendActionsForControlEvents:UIControlEventValueChanged];
  if (self.valueChangedCallback) {
    self.valueChangedCallback(self, self.currentValue);
  }
}

#pragma mark private helpers
- (BOOL)isMinimum {
  return self.currentValue == self.minimum;
}

- (BOOL)isMaximum {
  return self.currentValue == self.maximum;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark -  Responder
- (BOOL)canBecomeFirstResponder {
  return [self.textField canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
  return [self.textField becomeFirstResponder];
}

- (BOOL)canResignFirstResponder {
  return [self.textField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
  return [self.textField resignFirstResponder];
}

- (BOOL)isFirstResponder {
  return [self.textField isFirstResponder];
}

@end
