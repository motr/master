classdef AutoTrackSettingsController < handle
  
  properties
    catalyticController  % the parent CatalyticController
    
    % GUI handles
    fig  % the settings figure
    mainAxes  % the main axes, which shows the current frame ROI and foreground/background segmentation
    lighterthanbgmenu
    donebutton
    debugbutton
    fixbgpanel
    text4
    bgColorAxes
    bgColorImageGH
    eyedropperRadiobutton
    fillbutton
    radiusText
    radiusPlusButton
    radiusMinusButton
    thresholdText
    thresholdPlusButton
    thresholdMinusButton
    
    choosepatch  % true iff the user is currently in the process of drawing a rectangle in mainAxes
    % buttondownfcn
    im  % the image, limited to the ROI, for the current frame
%     nr  % number of rows in the ROI
%     nc  % number of cols in the ROI
    r0  % the lowest-index row of the ROI in the full frame
    r1  % the highest-index row of the ROI in the full frame
    c0  % the lowest-index col of the ROI in the full frame
    c1  % the highest-index col of the ROI in the full frame
    roiImageGH  % the image HG object, showing the ROI, with background blacked out (or whited out, depending)
    perimeterLine  % the line showing the boundary between foreground and background
    fillRegionBoundLine  % the line showing the current fill region
    fillRegionAnchorCorner  % the corner of the fill region that is fixed during the drag
    fillRegionPointerCorner  % the corner of the fill region under the pointer during the drag
  end  % properties
  
  methods
    % ---------------------------------------------------------------------
    function self=AutoTrackSettingsController(catalyticController)
      self.layout();
      self.catalyticController = catalyticController;
      
      % set defaults
      set(self.eyedropperRadiobutton,'value',0);
      %axes(self.bgColorAxes);
      self.catalyticController.initializeBackgroundImageForCurrentAutoTrack();
      set(self.thresholdText,'string',sprintf('Threshold: %.1f',self.catalyticController.getBackgroundThreshold()));
      lighterthanbg=self.catalyticController.getForegroundSign();
      if lighterthanbg == 1,
        set(self.lighterthanbgmenu,'value',1);
      elseif lighterthanbg == -1,
        set(self.lighterthanbgmenu,'value',2);
      else
        set(self.lighterthanbgmenu,'value',3);
      end
      set(self.radiusText,'string',sprintf('Track Radius: %.1f px',self.catalyticController.getMaximumJump()));
      
      self.choosepatch = false;
      % self.buttondownfcn = get(self.mainAxes,'buttondownfcn');
      
      self.showCurrentFrame();
      
      bgColor=self.catalyticController.getBackgroundColor();
      if isempty(bgColor) || isnan(bgColor) ,
        self.catalyticController.setBackgroundColor(median(self.im(:)));
      end
      %axes(self.bgColorAxes);
      self.bgColorImageGH= ...
        image('parent',self.bgColorAxes, ...
              'cdata',repmat(uint8(self.catalyticController.getBackgroundColor()),[1,1,3]));
      set(self.bgColorAxes,'xlim',[0.5 1.5],'ylim',[0.5 1.5]);    
      %axis off;      
      set(self.fig,'visible','on');
    end
    
    
    % ---------------------------------------------------------------------
    function showCurrentFrame(self)
      iFlies = self.catalyticController.getAutoTrackFly();
      f = self.catalyticController.getAutoTrackFrame();
      [isfore,dfore,xpred,ypred,thetapred,self.r0,self.r1,self.c0,self.c1,self.im] = ...
        self.catalyticController.backgroundSubtraction(iFlies,f);  %#ok
      %self.nr = self.r1-self.r0+1;
      %self.nc = self.c1-self.c0+1;
      %axes(self.mainAxes);
      %hold off;
      if ~isempty(self.roiImageGH) && ishandle(self.roiImageGH)
        delete(self.roiImageGH);
      end
%       foregroundSign=self.catalyticController.getForegroundSign();
%       if foregroundSign==1 ,
%         backgroundValue=0;
%       elseif foregroundSign==-1 ,
%         backgroundValue=255;
%       else
%         backgroundValue=0;
%       end
      %imColorized=self.im;
      %imColorized(~isfore)=backgroundValue;
      imColorized=colorizeSegmentation(self.im,isfore);
      %bgcurr=self.catalyticController.getBackgroundImageForCurrentAutoTrack();
      %bgcurr=bgcurr(self.r0:self.r1,self.c0:self.c1);
      self.roiImageGH = image('parent',self.mainAxes, ...
                              'xdata',[self.c0 self.c1], ...
                              'ydata',[self.r0 self.r1], ...
                              'cdata',imColorized);
      set(self.roiImageGH,'buttondownfcn',@(hObject,eventdata)self.mouseButtonDownInMainAxes(hObject,eventdata));
      set(self.mainAxes,'xlim',[self.c0-0.5 self.c1+0.5], ...
                        'ylim',[self.r0-0.5 self.r1+0.5]);
      %axis image;
      %colormap gray;
      %hold on;
%       bw = bwperim(isfore);
%       [r,c] = find(bw);
%       self.perimeterLine=line('parent',self.mainAxes, ...
%                               'xdata',c+self.c0-1, ...
%                               'ydata',r+self.r0-1, ...
%                               'color','r', ...
%                               'marker','.', ...
%                               'linestyle','none', ...
%                               'hittest','off');
      
      if ~isempty(self.fillRegionAnchorCorner) && ~isempty(self.fillRegionPointerCorner)
        if ~isempty(self.fillRegionBoundLine) && ishandle(self.fillRegionBoundLine) ,
          delete(self.fillRegionBoundLine);
        end
        self.fillRegionBoundLine = ...
          line('parent',self.mainAxes, ...
               'xdata',[self.fillRegionAnchorCorner(1),self.fillRegionAnchorCorner(1), ...
                        self.fillRegionPointerCorner(1),self.fillRegionPointerCorner(1),self.fillRegionAnchorCorner(1)], ...
               'ydata',[self.fillRegionAnchorCorner(2),self.fillRegionPointerCorner(2), ...
                        self.fillRegionPointerCorner(2),self.fillRegionAnchorCorner(2),self.fillRegionAnchorCorner(2)], ...
               'color','g');
      end
    end
    
    
    % ---------------------------------------------------------------------
    function thresholdPlusButtonTwiddled(self, hObject, eventdata)  %#ok
      % hObject    handle to thresholdPlusButton (see GCBO)
      % eventdata  reserved - to be defined in a future version of MATLAB
      % self    structure with self and user data (see GUIDATA)
      
      self.catalyticController.incrementBackgroundThreshold(1);
      set(self.thresholdText,'string',sprintf('Threshold: %.1f',self.catalyticController.getBackgroundThreshold()));
      self.showCurrentFrame();
      % guidata(hObject,self);
    end
    
    
    % ---------------------------------------------------------------------
    function thresholdMinusButtonTwiddled(self, hObject, eventdata)  %#ok
      % hObject    handle to thresholdMinusButton (see GCBO)
      % eventdata  reserved - to be defined in a future version of MATLAB
      % self    structure with self and user data (see GUIDATA)
      
      self.catalyticController.incrementBackgroundThreshold(-1);
      %self.catalyticController.bgthresh = self.catalyticController.bgthresh - .1;
      set(self.thresholdText,'string',sprintf('Threshold: %.1f',self.catalyticController.getBackgroundThreshold()));
      self.showCurrentFrame();
      % guidata(hObject,self);
    end
    
    
    
    % ---------------------------------------------------------------------
    function lighterthanbgmenuTwiddled(self, hObject, eventdata)  %#ok
      % hObject    handle to lighterthanbgmenu (see GCBO)
      % eventdata  reserved - to be defined in a future version of MATLAB
      % self    structure with self and user data (see GUIDATA)
      
      % Hints: contents = get(hObject,'String') returns lighterthanbgmenu contents as cell array
      %        contents{get(hObject,'Value')} returns selected item from lighterthanbgmenu
      
      v = get(hObject,'value');
      lighterthanbg=self.catalyticController.getForegroundSign();
      if v == 1
        
        if lighterthanbg == 1
          return;
        end
        self.catalyticController.setForegroundSign(1);
        self.showCurrentFrame();
        
      elseif v == 2
        
        if lighterthanbg == -1
          return;
        end
        self.catalyticController.setForegroundSign(-1);
        self.showCurrentFrame();
        
      else
        
        if lighterthanbg == 0
          return;
        end
        self.catalyticController.setForegroundSign(0);
        self.showCurrentFrame();
        
      end
      % guidata(hObject,self);
    end
    
    
    
    % ---------------------------------------------------------------------
    function donebuttonTwiddled(self, hObject, eventdata)  %#ok
      self.closeRequested();
    end
    
    
    
    % ---------------------------------------------------------------------
    function eyedropperRadiobuttonTwiddled(self, hObject, eventdata)  %#ok
      % Hint: get(hObject,'Value') returns toggle state of eyedropperRadiobutton
    end
    
    
    
    % ---------------------------------------------------------------------
    function mouseButtonDownInMainAxes(self, hObject, eventdata)  %#ok
      %fprintf('Entered mouseButtonDownInMainAxes()\n');
      pt = get(self.mainAxes,'currentpoint');
      [nr,nc]=size(self.im);
      x = min(max(1,round(pt(1,1))),nc);
      y = min(max(1,round(pt(1,2))),nr);
      
      if get(self.eyedropperRadiobutton,'Value')
        
        self.catalyticController.setBackgroundColor(self.im(y,x));
        %axes(self.bgColorAxes);
        set(self.bgColorImageGH, ...
            'cdata',repmat(uint8(self.catalyticController.getBackgroundColor()),[1,1,3]));
        %axis off;
        
      else
        
        if ~isempty(self.fillRegionBoundLine) && ishandle(self.fillRegionBoundLine)
          delete(self.fillRegionBoundLine);
        end
        self.fillRegionAnchorCorner = [x,y];
        self.fillRegionBoundLine = line('parent',self.mainAxes, ...
                            'xdata',[x,x,x,x,x], ...
                            'ydata',[y,y,y,y,y], ...
                            'color','g');
        self.choosepatch = true;
        
      end
      
      % guidata(hObject,self);
    end
    
    
    % ---------------------------------------------------------------------
    function debugbuttonTwiddled(self, hObject, eventdata)  %#ok
      keyboard;
    end
    
    
    % ---------------------------------------------------------------------
    function fillbuttonTwiddled(self, hObject, eventdata)  %#ok
      if isempty(self.fillRegionAnchorCorner) || isempty(self.fillRegionPointerCorner)
        msgbox('Drag a rectangle to select a patch to fill');
        return;
      end
      
      r0 = min(self.fillRegionAnchorCorner(2),self.fillRegionPointerCorner(2));
      r1 = max(self.fillRegionAnchorCorner(2),self.fillRegionPointerCorner(2));
      c0 = min(self.fillRegionAnchorCorner(1),self.fillRegionPointerCorner(1));
      c1 = max(self.fillRegionAnchorCorner(1),self.fillRegionPointerCorner(1));
      r0 = max(round(r0),1);
      r1 = min(round(r1),self.catalyticController.getNRows());
      c0 = max(round(c0),1);
      c1 = min(round(c1),self.catalyticController.getNCols());
      bgcurr=self.catalyticController.getBackgroundImageForCurrentAutoTrack();
      bgcurr(r0:r1,c0:c1) = self.catalyticController.getBackgroundColor();
      self.catalyticController.setBackgroundImageForCurrentAutoTrack(bgcurr);
      
      self.showCurrentFrame();
      % guidata(hObject,self);
    end
    
    
    
    % ---------------------------------------------------------------------
    function mouseMoved(self,hObject,eventdata)  %#ok
      %if isfield(self,'choosepatch') || ~self.choosepatch
      %fprintf('Entered mouseMoved()\n');
      if isempty(self.choosepatch) || ~self.choosepatch
        return
      end
      %fprintf('Entered mouseMoved() inner sanctum\n');
      
      pt = get(self.mainAxes,'currentpoint');
      x = pt(1,1);
      y = pt(1,2);
      %[nr,nc]=size(self.im);
      %if x < self.c0-0.5 || x > self.c1+0.5 || y < self.r0-0.5 || y > self.r1+0.5
        %fprintf('returning early!\n');
      %  return
      %end
      x = min(max(self.c0,round(x)),self.c1);
      y = min(max(self.r0,round(y)),self.r1);
      
      self.fillRegionPointerCorner = [x,y];
      set(self.fillRegionBoundLine,...
          'xdata',[self.fillRegionAnchorCorner(1),self.fillRegionAnchorCorner(1),x,x,self.fillRegionAnchorCorner(1)],...
          'ydata',[self.fillRegionAnchorCorner(2),y,y,self.fillRegionAnchorCorner(2),self.fillRegionAnchorCorner(2)]);
      
      % guidata(hObject,self);
    end
    
    
    % ---------------------------------------------------------------------
    function mouseButtonReleased(self,hObject,eventdata)  %#ok
      self.choosepatch = false;
    end
    
    
    
    % ---------------------------------------------------------------------
    function radiusPlusButtonTwiddled(self, hObject, eventdata)  %#ok
      self.catalyticController.incrementMaximumJump(+1);
      set(self.radiusText,'string',sprintf('Track Radius: %.1f px',self.catalyticController.getMaximumJump()));
      self.showCurrentFrame();
    end
    
    
    
    % ---------------------------------------------------------------------
    function radiusMinusButtonTwiddled(self, hObject, eventdata)  %#ok
      self.catalyticController.incrementMaximumJump(-1);
      set(self.radiusText,'string',sprintf('Track Radius: %.1f px',self.catalyticController.getMaximumJump()));
      self.showCurrentFrame();
    end
    
    
    
    % ---------------------------------------------------------------------
    function closeRequested(self)
      delete(self.fig);
    end
    
    
    
    % ---------------------------------------------------------------------
    function layout(self)      
      self.fig = figure(...
        'Units','characters',...
        'CloseRequestFcn',@(hObject,eventdata)self.closeRequested(),...
        'Color',[0.929411764705882 0.929411764705882 0.929411764705882],...
        'Colormap',gray(256),...
        'IntegerHandle','off',...
        'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
        'MenuBar','none',...
        'Name','Auto-track Settings',...
        'NumberTitle','off',...
        'PaperPosition',get(0,'defaultfigurePaperPosition'),...
        'Position',[103.666666666667 30.8333333333333 111.5 30.75],...
        'Resize','off',...
        'ToolBar','figure',...
        'WindowButtonMotionFcn',@(hObject,eventdata)self.mouseMoved(hObject,eventdata),...
        'WindowButtonUpFcn',@(hObject,eventdata)self.mouseButtonReleased(hObject,eventdata),...
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
        'ButtonDownFcn',@(hObject,eventdata)@(hObject,eventdata)self.mouseButtonDownInMainAxes(hObject,eventdata),...
        'clim',[0 255], ...
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
      
      self.lighterthanbgmenu = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)self.lighterthanbgmenuTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[71.1666666666667 8.23076923076925 36.3333333333333 2.15384615384615],...
        'String',{  'Light flies on dark background'; 'Dark flies on light background'; 'Other' },...
        'Style','popupmenu',...
        'Value',1,...
        'Tag','lighterthanbgmenu');
      
      self.donebutton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)self.donebuttonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[83.3333333333333 1.15384615384615 15 1.92307692307692],...
        'String','Done',...
        'Tag','donebutton');
      
      self.debugbutton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)self.debugbuttonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[83.1666666666667 4.30769230769231 15.5 2.23076923076923],...
        'String','Debug',...
        'Tag','debugbutton');
      
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
        'Tag','bgColorAxes');
%         'DataAspectRatio',[1 1 1], ...
            
      self.eyedropperRadiobutton = uicontrol(...
        'Parent',self.fixbgpanel,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)self.eyedropperRadiobuttonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[21.3333333333333 1.30769230769231 19 1.2],...
        'String','Eyedropper',...
        'Style','radiobutton',...
        'Tag','eyedropperRadiobutton');
      
      self.fillbutton = uicontrol(...
        'Parent',self.fixbgpanel,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)self.fillbuttonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[7 0.615384615384615 6.33333333333333 2.07692307692308],...
        'String','Fill',...
        'Tag','fillbutton');
      
      self.radiusText = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'FontSize',12.5,...
        'HorizontalAlignment','left',...
        'Position',[71.5 14.45 25 1.1],...
        'String','Track Radius: ',...
        'Style','text',...
        'Tag','radiusText');
      
      self.radiusPlusButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)self.radiusPlusButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[89.2+9 13.9 3.5 1.9],...
        'String','+',...
        'Tag','radiusPlusButton');
      
      self.radiusMinusButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)self.radiusMinusButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[93.5+9 13.9 3.5 1.9],...
        'String','-',...
        'Tag','radiusMinusButton');
      
      self.thresholdText = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'FontSize',12.5,...
        'HorizontalAlignment','left',...
        'Position',[71.5 11.85 25 1.1],...
        'String','Threshold: ',...
        'Style','text',...
        'Tag','thresholdText');
      
      self.thresholdPlusButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)self.thresholdPlusButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[89.2+9 11.3 3.5 1.9],...
        'String','+',...
        'Tag','thresholdPlusButton');
      
      self.thresholdMinusButton = uicontrol(...
        'Parent',self.fig,...
        'Units','characters',...
        'FontUnits','pixels',...
        'Callback',@(hObject,eventdata)self.thresholdMinusButtonTwiddled(hObject,eventdata),...
        'FontSize',12.5,...
        'Position',[93.5+9 11.3 3.5 1.9],...
        'String','-',...
        'Tag','thresholdMinusButton');      
    end  % method
    
  end  % methods
  
end  % classdef



