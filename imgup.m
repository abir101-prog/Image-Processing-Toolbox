function varargout = imgup(varargin)
% IMGUP MATLAB code for imgup.fig
%      IMGUP, by itself, creates a new IMGUP or raises the existing
%      singleton*.
%
%      H = IMGUP returns the handle to a new IMGUP or the handle to
%      the existing singleton*.
%
%      IMGUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMGUP.M with the given input arguments.
%
%      IMGUP('Property','Value',...) creates a new IMGUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before imgup_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to imgup_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help imgup

% Last Modified by GUIDE v2.5 09-Feb-2022 02:10:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imgup_OpeningFcn, ...
                   'gui_OutputFcn',  @imgup_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before imgup is made visible.
function imgup_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imgup (see VARARGIN)

% my code:
% unselect radio button for edge detection
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);
% create an empty canvas that can be used in the reset function
canvas_dim = 300;
empty_canvas = ones(canvas_dim) * 255; % white canvas
imshow(empty_canvas, 'Parent', handles.true_image);
imshow(empty_canvas, 'Parent', handles.processed_image);
handles.empty_canvas = empty_canvas;
% create operation list to contain previous operations:
handles.operations = {};
handles.allow_sequence = 0;  %initially it will not apply operation in sequence
% Choose default command line output for imgup
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes imgup wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = imgup_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in upload.
function upload_Callback(hObject, eventdata, handles)
% hObject    handle to upload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% usrvar = handles.zdata;
% axes(handles.imageplot);
% imagesc(handles.xdata, handles.ydata,usrvar);
[file, path] = uigetfile({'*.jpg'; '*.PNG'; '*.png'}, 'Select your image');
[img, cmap] = imread(fullfile(path, file));
% preprocessing the image to see if it is indexed image:
if ~isempty(cmap)
    img = ind2rgb(img, cmap);   % now it is normal image
end

% show the image:
axes(handles.true_image);
imshow(img);
% saving the image in the app:
handles = guidata(hObject);
filename = split(file, '.');
handles.filename = char(filename(1));
handles.image = img;    % updating handle with the real image
%clear operation list as new image is uploaded
handles.operations = {};
guidata(hObject, handles);   % making the update permanent


% --- Executes on button press in gray_scale.
function gray_scale_Callback(hObject, eventdata, handles)
% hObject    handle to gray_scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% unselect radio button for edge detection
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);
if ~isfield(handles, 'image')
    return;
end
handles = remove_slider(handles);
handles = remove_hist_plot(handles);

if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end

if length(size(img)) == 3 % rgb
    gray_img = rgb2gray(img);
else
    gray_img = img;
end
handles.p_image = gray_img;  % keeping the image for later to download
handles.process = 'gray';
handles = operation_manager(handles, gray_img);
guidata(hObject, handles);
imshow(gray_img, 'Parent', handles.processed_image);
%change the title of the processed image:
set(handles.processed_image_text, 'String', 'Processed Image: Gray Scale');


% --- Executes on button press in binary.
function binary_Callback(hObject, eventdata, handles)
% hObject    handle to binary (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% unselect radio button for edge detection
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);
% check is the image is loaded already
if ~isfield(handles, 'image')
    return;
end

handles = remove_slider(handles);
handles = remove_hist_plot(handles);
if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end
BW = double(im2bw(img));
axes(handles.processed_image);
imshow(BW);

handles = operation_manager(handles, BW);

handles.p_image = BW;  % keeping the image for later to download
handles.process = 'binary';
guidata(hObject, handles);
%change the title of the processed image:
set(handles.processed_image_text, 'String', 'Processed Image: Binary');

function handles = operation_manager(handles, p_img)
if handles.allow_sequence == 1
    handles.operations{length(handles.operations) + 1} = p_img;  
else
    handles.operations = {}; %clear the list of images first
    handles.operations{1} = p_img;
end

function handles = remove_slider(handles)
if isfield(handles, 'slider1')  %remove it since power trans is done
    delete(handles.slider1);
    handles = rmfield(handles, 'slider1');
    handles.gamma_text.String = "";
end

% --- Executes on selection change in filters_list.
function filters_list_Callback(hObject, eventdata, handles)
% hObject    handle to filters_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns filters_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from filters_list
% unselect radio button for edge detection
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);
if ~isfield(handles, 'image')
    return;
end
handles = remove_slider(handles);
handles = remove_hist_plot(handles);
if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end

contents = cellstr(get(hObject, 'String'));
current_val = contents{get(hObject, 'Value')};
switch current_val
    case 'Mean'
        h = ones(3) .* (1/9);
        img = imfilter(img, h);
        axes(handles.processed_image);
        imshow(img);
        handles.p_image = img;  % keeping the image for later to download
        handles = operation_manager(handles, img);
        guidata(hObject, handles);
    case 'Median'
        if length(size(img)) == 3  % rgb
            r_ch = img(:, :, 1);
            g_ch = img(:, :, 2);
            b_ch = img(:, :, 3);
            img_med = cat(3, medfilt2(r_ch), medfilt2(g_ch), medfilt2(b_ch));
        else
            img_med = medfilt2(img);
        end
        axes(handles.processed_image);
        imshow(img_med);
        handles.p_image = img_med;  % keeping the image for later to download
        handles = operation_manager(handles, img_med);
        guidata(hObject, handles);
    case 'Max'
        [r, c, channel] = size(img);
        new_img = zeros([r + 2, c + 2, channel]);
        new_img(2:r + 1, 2: c + 1, :) = img;  % border of the new image is zero
        % one channel at a time
        for ch=1:channel
            for i = 2: r + 1
                for j = 2: c + 1
                    % collect the 9 neighbor
                    max_val = -1;
                    for i_inc=-1:1
                        for j_inc = -1:1
                            max_val = max(max_val, new_img(i + i_inc, j + j_inc, ch));
                        end
                    end
                    img(i - 1, j - 1, ch) = max_val;
                end
            end
        end
        axes(handles.processed_image);
        imshow(img);
        handles.p_image = img;  % keeping the image for later to download
        handles = operation_manager(handles, img);
        guidata(hObject, handles);
    case 'Min'
        [r, c, channel] = size(img);
        new_img = zeros([r + 2, c + 2, channel]);
        new_img(2:r + 1, 2: c + 1, :) = img;  % border of the new image is zero
        % one channel at a time
        for ch=1:channel
            for i = 2: r + 1
                for j = 2: c + 1
                    % collect the 9 neighbor
                    min_val = 500; % > 255
                    for i_inc=-1:1
                        for j_inc = -1:1
                            min_val = min(min_val, new_img(i + i_inc, j + j_inc, ch));
                        end
                    end
                    img(i - 1, j - 1, ch) = min_val;
                end
            end
        end
        axes(handles.processed_image);
        imshow(img);
        handles.p_image = img;  % keeping the image for later to download
        handles = operation_manager(handles, img);
        guidata(hObject, handles);
end
handles.process = [current_val '-filter'];
guidata(hObject, handles);
%change the title of the processed image:
set(handles.processed_image_text, 'String', strcat('Processed Image: ', current_val, ' Filter'));

% --- Executes during object creation, after setting all properties.
function filters_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filters_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in edge_prewitt.
function edge_prewitt_Callback(hObject, eventdata, handles)
% hObject    handle to edge_prewitt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edge_prewitt
if ~isfield(handles, 'image')
    return;
end
handles = remove_slider(handles);
handles = remove_hist_plot(handles);

if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end

if length(size(img)) == 3
    img = im2gray(img);
end
edgy = edge(img, 'prewitt');
axes(handles.processed_image);
imshow(edgy);
handles.p_image = edgy;  % keeping the image for later to download
handles.process = 'prewitt';
handles = operation_manager(handles, edgy);

guidata(hObject, handles);
%change the title of the processed image:
set(handles.processed_image_text, 'String', 'Processed Image: Edge Detect - Prewitt');


% --- Executes on button press in edge_sobel.
function edge_sobel_Callback(hObject, eventdata, handles)
% hObject    handle to edge_sobel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edge_sobel

if ~isfield(handles, 'image')
    return;
end
handles = remove_slider(handles);
handles = remove_hist_plot(handles);
if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end

if length(size(img)) == 3
    img = im2gray(img);
end
edgy = edge(img, 'sobel');
axes(handles.processed_image);
imshow(edgy);
handles.p_image = edgy;  % keeping the image for later to download
handles.process = 'sobel';
handles = operation_manager(handles, edgy);

guidata(hObject, handles);
%change the title of the processed image:
set(handles.processed_image_text, 'String', 'Processed Image: Edge Detect - Sobel');

% --- Executes on button press in reset.
function reset_Callback(hObject, eventdata, handles)
% hObject    handle to reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% removes all images from the axes
if isfield(handles, 'image')   % removing the current image from the app
    handles = rmfield(handles, 'image');
    handles = rmfield(handles, 'filename');
end

imshow(handles.empty_canvas, 'Parent', handles.true_image);
imshow(handles.empty_canvas, 'Parent', handles.processed_image);
handles = remove_slider(handles);
handles = remove_hist_plot(handles);
handles.operations = {};
guidata(hObject, handles);
% unselect radio button 
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);


% --- Executes on button press in log_trans.
function log_trans_Callback(hObject, eventdata, handles)
% hObject    handle to log_trans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% unselect radio button for edge detection
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);
if ~isfield(handles, 'image')
    return;
end
handles = remove_slider(handles);
handles = remove_hist_plot(handles);

if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end
img = double(img);
k = 255 / (1 + log(max(img, [], 'all')));
new_img = uint8(k * log(1 + img));
axes(handles.processed_image);
imshow(new_img);
handles.p_image = new_img;  % keeping the image for later to download
handles.process = 'log';
handles = operation_manager(handles, new_img);

guidata(hObject, handles);
%change the title of the processed image:
set(handles.processed_image_text, 'String', 'Processed Image: Log Transformation');


% --- Executes on button press in power_law.
function power_law_Callback(hObject, eventdata, handles)
% hObject    handle to power_law (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% unselect radio button for edge detection
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);
if ~isfield(handles, 'image')
    return;
end
handles = remove_hist_plot(handles);

% create the slider:
if ~isfield(handles, 'slider1')
    handles.slider1 = uicontrol('style','slider', 'position',[400,205,240,20]);
    handles.slider1.Callback = @slider1_Callback;
    handles.slider1.Max = 4;
    handles.slider1.Min = 0;

    handles.gamma_text.String = 'Gamma:';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isfield(handles, 'gamma')
    handles.gamma = 2;
end
gamma = handles.gamma;
if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end

img = double(img);
[~, ~, ch] = size(img);
for i=1:ch
    Imax = max(img(:, :, i), [], "all");
    Inorm = img(:, :, i) ./ Imax;
    new_img(:, :, i) = 255 * exp(gamma .* log(Inorm));
end
new_img = uint8(new_img);
axes(handles.processed_image);
imshow(new_img);
handles.p_image = new_img;  % keeping the image for later to download
handles.process = 'pow';
handles = operation_manager(handles, new_img);

guidata(hObject, handles);
%change the title of the processed image:
set(handles.processed_image_text, 'String', 'Processed Image: Power Law Transformation');


% --- Executes on button press in hist_equal.
function hist_equal_Callback(hObject, eventdata, handles)
% hObject    handle to hist_equal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% unselect radio button for edge detection
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);
if ~isfield(handles, 'image')
    return;
end
handles = remove_slider(handles);
handles = remove_hist_plot(handles);
if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end

[count1, bin1] = imhist(img, 64);
if length(size(img)) == 2 %gray
    new_img = histeq(img);
else
    hsv = rgb2hsv(img);
    heq = histeq(hsv(:, :, 3));  % hist on the intensity
    histed_hsv = hsv;
    histed_hsv(:, :, 3) = heq;  % changing intensity with the histed one
    new_img = hsv2rgb(histed_hsv);
end
[count2, bin2] = imhist(new_img, 64);
ax1 = uiaxes(handles.figure1, "Position", [10, 0, 310, 200]);
ax2 = uiaxes(handles.figure1, "Position", [330, 0, 310, 200]);
handles.hist_ax = [ax1 ax2];
axes(ax1);
bar(bin1, count1, 'BarWidth', 1);
title("Original");
axes(ax2);
bar(bin2, count2, 'BarWidth', 1);
title("Processed");
handles.p_image = new_img;  % keeping the image for later to download
handles.process = 'hist';
handles = operation_manager(handles, new_img);
guidata(hObject, handles);
axes(handles.processed_image);
imshow(new_img);
%change the title of the processed image:
set(handles.processed_image_text, 'String', 'Processed Image: Histogram Equalization');

function handles = remove_hist_plot(handles)
if isfield(handles, 'hist_ax')
    delete(handles.hist_ax);
    handles = rmfield(handles, "hist_ax");
end

% --- Executes on button press in segment_adapt.
function segment_adapt_Callback(hObject, eventdata, handles)
% hObject    handle to segment_adapt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% unselect radio button for edge detection
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);
if ~isfield(handles, 'image')
    return;
end
handles = remove_slider(handles);
handles = remove_hist_plot(handles);
if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end

if length(size(img)) == 3
    img = rgb2gray(img);
end
bw = imbinarize(img, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity',0.45); % text are darker add for text: , 'ForegroundPolarity', 'dark'
bw = double(bw);
handles.p_image = bw;  % keeping the image for later to download
handles.process = 'adapt';
guidata(hObject, handles);
axes(handles.processed_image);
imshow(bw);
handles.p_image = bw;  % keeping the image for later to download
handles = operation_manager(handles, bw);

guidata(hObject, handles);
%change the title of the processed image:
set(handles.processed_image_text, 'String', 'Processed Image: Segmentation - Adaptive');


% --- Executes on button press in segment_otsu.
function segment_otsu_Callback(hObject, eventdata, handles)
% hObject    handle to segment_otsu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% unselect radio button for edge detection
set(handles.edge_prewitt, 'Value', 0);
set(handles.edge_sobel, 'Value', 0);
if ~isfield(handles, 'image')
    return;
end
handles = remove_slider(handles);
handles = remove_hist_plot(handles);
if handles.allow_sequence == 1 && ~isempty(handles.operations)
    img = handles.operations{end};
else
    img = handles.image;
end

if length(size(img)) == 3  % make it gray
    img = rgb2gray(img);
end
T = graythresh(img);  % threshold: uses otsu
bw = double(imbinarize(img, T));
handles.p_image = bw;  % keeping the image for later to download
guidata(hObject, handles);
axes(handles.processed_image);
imshow(bw);
handles.p_image = bw;  % keeping the image for later to download
handles.process = 'otsu';
handles = operation_manager(handles, bw);

guidata(hObject, handles);
%change the title of the processed image:
set(handles.processed_image_text, 'String', 'Processed Image: Segmentation - Otsu');


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Download.
function Download_Callback(hObject, eventdata, handles)
% hObject    handle to Download (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles, 'image')
    return;
end
imwrite(handles.p_image, [handles.filename '-' handles.process '.png']);


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles = guidata(hObject);
if ~isfield(handles, 'image')
    return;
end
% set(hObject, 'Max', 4);
% set(hObject, 'Min', 0);
handles.gamma = get(hObject, 'Value');
guidata(hObject, handles);
power_law_Callback(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in allow_sequence.
function allow_sequence_Callback(hObject, eventdata, handles)
% hObject    handle to allow_sequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of allow_sequence
val = get(hObject, 'Value');
handles.allow_sequence = val;
if val == 0 && length(handles.operations) > 1
    %clear operations list
    handles.operations = {handles.operations{length(handles.operations)}}; %only last one is kept
end
guidata(hObject, handles);


% --- Executes on button press in undo_btn.
function undo_btn_Callback(hObject, eventdata, handles)
% hObject    handle to undo_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.allow_sequence == 0
    return;
end
n = length(handles.operations) - 1;  % one will be removed
if n < 1
    return;
end
for i=1:n
    new_operations{i} = handles.operations{i};
end
handles.p_image = handles.operations{n};
handles.operations = new_operations;
guidata(hObject, handles);
axes(handles.processed_image);
imshow(handles.p_image);
