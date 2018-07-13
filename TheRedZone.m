function TheRedZone(user_folder, subfolder, filename, seconds, fps)

sfolder=user_folder;
ssfolder=subfolder;
sname=filename;
nframes=seconds*fps;
ndelay=(1/fps);

folderName=[sfolder , '\' , ssfolder];
mkdir(folderName);

% Drawing TheRedZone
% Create axes control.
handleToAxes = axes();
% Get the handle to the image in the axes.'
imageSizeX = 768;
imageSizeY = 1024;
hImage = image(zeros(imageSizeX, imageSizeY,'uint8'));
% Reset image magnification. Required if you ever displayed an image
% in the axes that was not the same size as your webcam image.
hold off;
axis auto;
axis on;
% Enlarge figure to full screen.
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);

% Setting up camera and settings
obj=videoinput('winvideo',3,'Y800_1024x768');
set(obj, 'SelectedSourceName' , 'input1');
set(obj, 'ReturnedColorSpace', 'grayscale');
set(obj.source,'Gain',0);
set(obj.source,'Brightness',0);
set(obj.source,'Exposure', -7);

preview(obj, hImage);
hold on

% Making cirle
r = 300;
x0 = 500;
y0 = 400;
pos = [x0-r, y0-r, 2*r, 2*r];


[columnsInImage, rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);

circlePixels = (rowsInImage - y0).^2 + (columnsInImage - x0).^2 <= r.^2;
disp(~circlePixels);


rectangle('Position', pos, 'Curvature', [1,1], 'EdgeColor','r','LineWidth',1)