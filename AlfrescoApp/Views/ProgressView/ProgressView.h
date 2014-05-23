//
//  ProgressView.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 13/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

@interface ProgressView : UIView

@property (nonatomic, weak) IBOutlet UILabel *progressInfoLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressBar;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@end
