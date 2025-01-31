%Input is 3D matrix, looks at z-slices
function SliderValue = GUI_slider1(dbin)

dbin = permute(dbin, [2,3,1]);

size_im = size(dbin,3);
%// Create GUI controls
handles.figure = figure('Position',[200 0 800 800],'Units','Pixels');

handles.axes1 = axes('Units','Pixels','Position',[120,200,800,600]);

handles.Slider1 = uicontrol('Style','slider','Position',[120 40 800 100],'Min',1,'Max',size_im,'value',1,'SliderStep',[1/(size_im-1) 1],'Callback',@SliderCallback);

%handles.Edit1 = uicontrol('Style','Edit','Position',[250 450 100 20],'String','Update Me');
%handles.Text1 = uicontrol('Style','Text','Position',[180 450 70 20],'String','Slider Value:');

handles.xrange = 1:200; %// Use to generate dummy data to plot.

guidata(handles.figure,handles); %// Update the handles structure.


  
  uiwait
  
    function SliderCallback(~,~) %// This is the slider callback, executed when you release the it or press the arrows at each extremity. 

        handles = guidata(gcf);

        SliderValue = get(handles.Slider1,'Value');
        SliderValue = round(SliderValue);
       % set(handles.Edit1,'String',num2str(SliderValue));
        imagesc(dbin(:,:,round(SliderValue)), 'Parent', handles.axes1)
        
        t = (SliderValue-1);
        
        title(['z = ', num2str(t+1)])
        xlabel('column')
        ylabel('row')
        %caxis([0 0.7])
        %caxis([0 255])
        %caxis([-1e-6 1e-6])
      % caxis([0 8e-4])
      %caxis([5 100])
      %  colorbar
        colormap(gray)
        axis image
      %loa 
   
      %
    %caxis([-1 1])
     colorbar
        %plot(handles.xrange, imagesc(dbin(:,:,round(SliderValue))),'Parent',handles.axes1);
    end




end