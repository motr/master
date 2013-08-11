classdef AutoTrackSettingsView < handle
  
  properties (SetAccess=private)
    model  % our model
    
    % GUI handles
    fig  % the settings figure
    mainAxes  % the main axes, which shows the current frame ROI and foreground/background segmentation
    foregroundSignPopup
    fixbgpanel
    text4
    bgColorAxes
    bgColorImageGH
    eyedropperRadiobutton
    fillbutton
    trackingROIHalfWidthText
    trackingROIHalfWidthPlusButton
    trackingROIHalfWidthMinusButton
    thresholdText
    thresholdPlusButton
    thresholdMinusButton
    debugbutton
    doneButton
    cancelButton
    
    roiImageGH  % the image HG object, showing the ROI, with background blacked out (or whited out, depending)
    %perimeterLine  % the line showing the boundary between foreground and background
    fillRegionBoundLine  % the line showing the current fill region    
    
    fillRegionAnchorCorner
    fillRegionPointerCorner
    choosepatch  % true iff the user is currently in the process of drawing a rectangle in mainAxes
    
end  % properties
  
  methods
    % ---------------------------------------------------------------------
    function self=AutoTrackSettingsView(model,controller)      
      self.model=model;
      self.choosepatch = false;      
      
      self.fig = figure(...
        'Units','characters',...
        'CloseRequestFcn',@(hObject,eventdata)controller.closeRequested(),...
        'Color',[0.929411764705882 0.929411764705882 0.929411764705882],...
        'Colormap',gray(256),...
        'IntegerHandle','off',...
        'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
        'MenuBar','none',...
        'Name','Auto-track Settings...',...
        'NumberTitle','off',...
        'PaperPosition',get(0,'defaultfigurePaperPosition'),...
        'Position',[103.666666666667 30.8333333333333 111.5 30.75],...
        'Resize','off',...
        'ToolBar','figure',...
        'WindowButtonMotionFcn',@(hObject,eventdata)controller.mouseMoved(hObject,eventdata),...
        'WindowButtonUpFcn',@(hObject,eventdata)controller.mouseButtonReleased(hObject,eventdata),...
        'HandleVisibility','callback',...
        'WindowStyle','normal', ...
        'UserData',[],...
        'Tag','fig',...
        'Visible','on');
      
      self.mainAxes = axes(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Position',[2.5 1.58333333333333 64.5 28.25],...
        'FontSize',12.5,...
        'LooseInset',[14.56 3.55666666666667 10.64 2.425],...
        'ButtonDownFcn',@(hObject,eventdata)@(hObject,eventdata)controller.mouseButtonDownInMainAxes(hObject,eventdata),...
        'clim',[0 255], ...
        'hittest','on',...
        'ydir','reverse', ...
        'dataaspectratio',[1 1 1], ...
        'Tag','mainAxes');
%         'CameraPosition',[0.5 0.5 9.16025403784439],...
%         'CameraPositionMode',get(0,'defaultaxesCameraPositionMode'),...
%         'XColor',get(0,'defaultaxesXColor'),...
%         'YColor',get(0,'defaultaxesYColor'),...
%         'ZColor',get(0,'defaultaxesZColor'),...
%         'Color',get(0,'defaultaxesColor'),...
%         'ColorOrder',get(0,'defaultaxesColorOrder'),...
      
      self.roiImageGH = ...
        image('parent',self.mainAxes, ...
              'hittest','on', ...
              'buttondownfcn',@(hObject,eventdata)controller.mouseButtonDownInMainAxes(hObject,eventdata));

      self.foregroundSignPopup = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.foregroundSignPopupTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[71.1666666666667 8.23076923076925 36.3333333333333 2.15384615384615],...
        'String',{  'Light flies on dark background'; 'Dark flies on light background'; 'Other' },...
        'Style','popupmenu',...
        'Value',1,...
        'Tag','foregroundSignPopup');
      
      self.fixbgpanel = uipanel(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'FontSize',12.5,...
        'Title','Fix Background',...
        'Tag','fixbgpanel',...
        'UserData',[],...
        'Clipping','on',...
        'Position',[67.6666666666667 16.3846153846154 41.1666666666667 12.9230769230769]);
      
      self.text4 = uicontrol(...
        'Parent',self.fixbgpanel,...
        'Units','characters',...
        'FontUnits','pixels',...
        'CData',[],...
        'FontSize',12.5,...
        'HorizontalAlignment','left',...
        'Position',[1.66666666666667 3.38461538461539 28.6666666666667 7.92307692307692],...
        'String',{  '1) To select a patch to fill, drag a rectangle.'; '2) To change the patch color, select using the eyedropper. '; '3) Click Fill.' },...
        'Style','text',...
        'UserData',[],...
        'Tag','text4');
      
      self.bgColorAxes = axes(...
        'Parent',self.fixbgpanel,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Position',[31 5.30769230769231 8.66666666666667 4.23076923076923],...
        'FontSize',12.5,...
        'clim',[0 255], ...
        'ydir','reverse', ...
        'Box','on', ...
        'Layer','top', ...
        'xtick',[], ...
        'ytick',[], ...
        'xlim',[0.5 1.5], ...
        'ylim',[0.5 1.5], ...
        'Tag','bgColorAxes');
            
      self.bgColorImageGH= ...
        image('parent',self.bgColorAxes, ...
              'cdata',repmat(uint8(self.model.backgroundColor),[1,1,3]));

      self.eyedropperRadiobutton = uicontrol(...
        'Parent',self.fixbgpanel,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.eyedropperRadiobuttonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[21.3333333333333 1.30769230769231 19 1.2],...
        'String','Eyedropper',...
        'Style','radiobutton',...
        'value',0, ...
        'Tag','eyedropperRadiobutton');
      
      self.fillbutton = uicontrol(...
        'Parent',self.fixbgpanel,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.fillbuttonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[7 0.615384615384615 6.33333333333333 2.07692307692308],...
        'String','Fill',...
        'Enable','off',...
        'Tag','fillbutton');
      
      self.trackingROIHalfWidthText = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'FontSize',12.5,...
        'HorizontalAlignment','left',...
        'Position',[68 14.45 32 1.1],...
        'String','ROI Half-Width:',...
        'Style','text',...
        'Tag','trackingROIHalfWidthText');
      
      self.trackingROIHalfWidthPlusButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.trackingROIHalfWidthPlusButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[100 13.9 3.5 1.9],...
        'String','+',...
        'Tag','trackingROIHalfWidthPlusButton');
      
      self.trackingROIHalfWidthMinusButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.trackingROIHalfWidthMinusButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[100+4.3 13.9 3.5 1.9],...
        'String','-',...
        'Tag','trackingROIHalfWidthMinusButton');
      
      self.thresholdText = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'FontSize',12.5,...
        'HorizontalAlignment','left',...
        'Position',[68 11.85 25 1.1],...
        'String','Threshold: ',...
        'Style','text',...
        'Tag','thresholdText');
      
      self.thresholdPlusButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.thresholdPlusButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[100 11.3 3.5 1.9],...
        'String','+',...
        'Tag','thresholdPlusButton');
      
      self.thresholdMinusButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.thresholdMinusButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[100+4.3 11.3 3.5 1.9],...
        'String','-',...
        'Tag','thresholdMinusButton');      
      
      self.debugbutton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.debugbuttonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[83.1666666666667 4.30769230769231 15.5 2.23076923076923],...
        'String','Debug',...
        'visible','off', ...
        'Tag','debugbutton');      

      fixbgpanelPosition=get(self.fixbgpanel,'position');
      fixbgpanelXOffset=fixbgpanelPosition(1);
      fixbgpanelWidth=fixbgpanelPosition(3);
      %fixbgpanelCenterX=fixbgpanelXOffset+fixbgpanelWidth/2;
      doneCancelInterButtonWidth=4;  % chars
      doneCancelButtonWidth=15;
      doneCancelButtonHeight=2;
      doneCancelButtonYOffset=2;
      doneCancelButtonBBBoxWidth=2*doneCancelButtonWidth+doneCancelInterButtonWidth;
      doneButtonXOffset=fixbgpanelXOffset+(fixbgpanelWidth-doneCancelButtonBBBoxWidth)/2;
      cancelButtonXOffset=doneButtonXOffset+doneCancelButtonWidth+doneCancelInterButtonWidth;
      
      self.doneButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.doneButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[doneButtonXOffset doneCancelButtonYOffset doneCancelButtonWidth doneCancelButtonHeight],...
        'String','Done',...
        'Tag','doneButton');
      
      self.cancelButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)controller.cancelButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[cancelButtonXOffset doneCancelButtonYOffset doneCancelButtonWidth doneCancelButtonHeight],...
        'String','Cancel',...
        'Tag','cancelButton');

      % Sync with the model
      self.update();
      
      % Make visible
      set(self.fig,'visible','on');
    end
    

    % ---------------------------------------------------------------------
    function r=getMainAxesCurrentPoint(self)  %#ok
      pt = get(self.mainAxes,'currentpoint');
      %[nr,nc]=size(self.currentFrame);
      r=pt(1,:);  % the <x,y> vector
    end

    
    % ---------------------------------------------------------------------
    function startFillRegionDrag(self,x,y) 
      if ~isempty(self.fillRegionBoundLine) && ishandle(self.fillRegionBoundLine)
        delete(self.fillRegionBoundLine);
      end
      self.fillRegionAnchorCorner = [x,y];
      self.fillRegionPointerCorner=self.fillRegionAnchorCorner;
      self.fillRegionBoundLine = ...
        line('parent',self.mainAxes, ...
             'xdata',[x,x,x,x,x], ...
             'ydata',[y,y,y,y,y], ...
             'zdata',[1 1 1 1 1], ...
             'color','g');
      self.choosepatch = true;
    end
    
    
    % ---------------------------------------------------------------------      
    function updateSegmentationPreview(self)
      r0=self.model.r0;
      r1=self.model.r1;
      c0=self.model.c0;
      c1=self.model.c1;      
      currentFrameROI=self.model.currentFrame(r0:r1,c0:c1); 
      backgroundImageROI=self.model.backgroundImage(r0:r1,c0:c1);
      isfore= ...
        foregroundSegmentation(currentFrameROI, ...
                               backgroundImageROI, ...
                               self.model.foregroundSign, ...
                               self.model.backgroundThreshold);

%       if ~isempty(self.roiImageGH) && ishandle(self.roiImageGH)
%         delete(self.roiImageGH);
%       end
      imColorized=colorizeSegmentation(currentFrameROI,isfore);
%       self.roiImageGH = image('parent',self.mainAxes, ...
%                               'hittest','on',...
%                               'xdata',[c0 c1], ...
%                               'ydata',[r0 r1], ...
%                               'cdata',imColorized);
%       set(self.roiImageGH,'buttondownfcn',@(hObject,eventdata)controller.mouseButtonDownInMainAxes(hObject,eventdata));
      set(self.roiImageGH, ...
          'xdata',[c0 c1], ...
          'ydata',[r0 r1], ...
          'cdata',imColorized);

      set(self.mainAxes,'xlim',[c0-0.5 c1+0.5], ...
                        'ylim',[r0-0.5 r1+0.5]);
%       bw = bwperim(isfore);
%       [r,c] = find(bw);
%       self.perimeterLine=line('parent',self.mainAxes, ...
%                               'xdata',c+self.model.c0-1, ...
%                               'ydata',r+self.model.r0-1, ...
%                               'color','r', ...
%                               'marker','.', ...
%                               'linestyle','none', ...
%                               'hittest','off');
    end  % method
    
    
    % ---------------------------------------------------------------------
    function continueFillRegionDrag(self,x,y)
      self.fillRegionPointerCorner=[x y];
      xAnchor=self.fillRegionAnchorCorner(1);
      yAnchor=self.fillRegionAnchorCorner(2);
      xPointer=self.fillRegionPointerCorner(1);
      yPointer=self.fillRegionPointerCorner(2);
      set(self.fillRegionBoundLine,...
          'xdata',[xAnchor,xAnchor,xPointer,xPointer,xAnchor],...
          'ydata',[yAnchor,yPointer,yPointer,yAnchor,yAnchor]);
    end

    
    % ---------------------------------------------------------------------
    function [fillRegionAnchorCorner,fillRegionPointerCorner]=endFillRegionDrag(self)
      self.choosepatch = false;
      % If the rectangle is of zero area, delete it
      if all(self.fillRegionAnchorCorner==self.fillRegionPointerCorner)
        delete(self.fillRegionBoundLine);
        self.fillRegionBoundLine=[];
        self.fillRegionAnchorCorner=[];
        self.fillRegionPointerCorner=[];
      end
      set(self.fillbutton,'enable',onIff(~isempty(self.fillRegionAnchorCorner)));
      fillRegionAnchorCorner=self.fillRegionAnchorCorner;
      fillRegionPointerCorner=self.fillRegionPointerCorner;
    end

    % ---------------------------------------------------------------------
    function updateBackgroundColorImage(self)
      set(self.bgColorImageGH, ...
          'cdata',repmat(uint8(self.model.backgroundColor),[1,1,3]));
    end
    
    % ---------------------------------------------------------------------
    function updateFillRegionBoundLine(self)
      if isempty(self.fillRegionAnchorCorner) || isempty(self.fillRegionPointerCorner) 
        if ~isempty(self.fillRegionBoundLine)
          if ishandle(self.fillRegionBoundLine)
            delete(self.fillRegionBoundLine);
          end
          self.fillRegionBoundLine=[];
        end
      else
        % case where fill region is defined
        xAnchor=self.fillRegionAnchorCorner(1);
        yAnchor=self.fillRegionAnchorCorner(2);
        xPointer=self.fillRegionPointerCorner(1);
        yPointer=self.fillRegionPointerCorner(2);
        if isempty(self.fillRegionBoundLine) || ~ishandle(self.fillRegionBoundLine)
          self.fillRegionBoundLine = ...
            line('parent',self.mainAxes, ...
                 'xdata',[xAnchor,xAnchor,xPointer,xPointer,xAnchor],...
                 'ydata',[yAnchor,yPointer,yPointer,yAnchor,yAnchor], ...
                 'zdata',[1 1 1 1 1], ...
                 'color','g');
        else
          set(self.fillRegionBoundLine,...
              'xdata',[xAnchor,xAnchor,xPointer,xPointer,xAnchor],...
              'ydata',[yAnchor,yPointer,yPointer,yAnchor,yAnchor]);
        end
      end
    end  % method
    
    
    % ---------------------------------------------------------------------
    function updateTrackingROIHalfWidthText(self)
      set(self.trackingROIHalfWidthText,'string',sprintf('ROI Half-Width: %.1f px',self.model.trackingROIHalfWidth));
    end
    
    
    
    % ---------------------------------------------------------------------
    function updateBackgroundThresholdText(self)
      set(self.thresholdText,'string',sprintf('Threshold: %.1f',self.model.backgroundThreshold));
    end
    
    
    
    % ---------------------------------------------------------------------
    function close(self)
      delete(self.fig);
    end
    

%     % ---------------------------------------------------------------------
%     function delete(self)
%       delete(self.fig);
%     end
    

    % ---------------------------------------------------------------------
    function updateForegroundSignPopup(self)
      if self.model.foregroundSign == 1,
        set(self.foregroundSignPopup,'value',1);
      elseif self.model.foregroundSign == -1,
        set(self.foregroundSignPopup,'value',2);
      else
        set(self.foregroundSignPopup,'value',3);
      end
    end  % method
    
    
    % ---------------------------------------------------------------------
    function update(self)
      self.updateBackgroundColorImage();
      self.updateForegroundSignPopup();
      self.updateTrackingROIHalfWidthText();
      self.updateBackgroundThresholdText();
      self.updateFillRegionBoundLine();
      self.updateSegmentationPreview();
    end
    
  end  % methods
  
end  % classdef
