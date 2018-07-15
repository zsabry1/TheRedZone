function TheRedZone(seconds, fps)

nframes=seconds*fps;
ndelay=(1/fps);

% Create an arduino object
a = arduino('com3','uno');

% Drawing TheRedZone
% Create axes control.
handleToAxes = axes();
% Get the handle to the image in the axes.'
imageSizeX = 768;
imageSizeY = 1024;
hImage = image(zeros(imageSizeX, imageSizeY,'uint8'));

% Enlarge figure to full screen.
%set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);

% Setting up camera and settings
obj=videoinput('gentl',1,'Mono8');
set(obj.source,'AcquisitionFrameRate',4);
set(obj.source,'AcquisitionFrameRateEnable','True');
set(obj.source,'ExposureAuto','Off');
set(obj.source,'ExposureTime', 5000);
triggerconfig(obj, 'manual');


preview(obj, hImage);
hold on

% Making cirle
% Coordinate info
r = 300;
x0 = 500;
y0 = 400;
pos = [x0-r, y0-r, 2*r, 2*r];

% Binary matrix of points that lay outside circle
%[columnsInImage, rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
%circlePixels = (rowsInImage - y0).^2 + (columnsInImage - x0).^2 <= r.^2;

rectangle('Position', pos, 'Curvature', [1,1], 'EdgeColor','r','LineWidth',1)

% Initializing capture
loop=0;
while(loop==0)
    choice = questdlg('Ready?','settings','yes','no','yes');
    % handle response
    switch choice
        case 'yes'
            loop = 1;
        case 'no'
            loop = 0;
            pause(30);
    end
end


for n=1:nframes
    tic;
    percent = (n/nframes)*100;
    disp(percent);
    frame=getsnapshot(obj);

    %%% Finding Centroid %%%
    % logical operation
    thresholdValue = 51; %not fixed; set range
    binaryImage = frame < thresholdValue; % Bright objects will be chosen if you use >.
    
    % Do a "hole fill" to get rid of any background pixels or "holes" inside the blobs.
    binaryImage = imfill(binaryImage, 'holes');

    binar = ExtractNLargestBlobs(binaryImage, 1);

    % Get all the blob properties
    blobMeasurements = regionprops(binar, frame, 'all');

    %blobArea = blobMeasurements.Area;		% Get area. % Plot x y coordinates to plot track
    %blobPerimeter = blobMeasurements.Perimeter;		% Get perimeter.
    blobCentroid = blobMeasurements.Centroid;		% Get centroid one at a time

    % Get centroid coordinates
    centroidX = blobCentroid(1);
    centroidY = blobCentroid(2);
    
    coord_offset = [x0,y0;centroidX, centroidY];
    d = pdist(coord_offset,'euclidean');
    
%    if d >= r
%        disp('outside');
%    else
%        disp('inside');
%    end

    hold on; % Don't blow away image.
    

    if d >= r
        writeDigitalPin(a, 'D12', 1);
        plot(centroidX, centroidY, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
    else
        writeDigitalPin(a, 'D12', 0);
        plot(centroidX, centroidY, 'g+', 'MarkerSize', 10, 'LineWidth', 2);
    end
    
    % Now use the keeper blobs as a mask on the original image.
    % This will let us display the original image in the regions of the keeper blobs.
    %maskedTissue = gray; % Simply a copy at first.
    %maskedTissue(binar) = 0;  % Set all non-keeper pixels to zero.
    %imshow(binaryImage);

    drawnow; % Force display to update immediately
    
    %img8bits=frame;
    %slongname=[ folderName, '\' , sname , num2str(n), '.jpeg'];
    %imwrite(img8bits, slongname, 'jpeg', 'bitdepth', 8);
    
    toc;
    pause(ndelay-toc);
end


function binaryImage = ExtractNLargestBlobs(binaryImage, numberToExtract)
try
	% Get all the blob properties.  Can only pass in originalImage in version R2008a and later.
	[labeledImage, ~] = bwlabel(binaryImage);
	blobMeasurements = regionprops(labeledImage, 'area');
	% Get all the areas
	allAreas = [blobMeasurements.Area];
    if numberToExtract > 0
		% For positive numbers, sort in order of largest to smallest.
		% Sort them.
		[~, sortIndexes] = sort(allAreas, 'descend');
    elseif numberToExtract < 0
		% For negative numbers, sort in order of smallest to largest.
		% Sort them.
		[~, sortIndexes] = sort(allAreas, 'ascend');
		% Need to negate numberToExtract so we can use it in sortIndexes later.
		numberToExtract = -numberToExtract;
	else
		% numberToExtract = 0.  Shouldn't happen.  Return no blobs.
		binaryImage = false(size(binaryImage));
		return;
    end
	% Extract the "numberToExtract" largest blob(a)s using ismember().
	biggestBlob = ismember(labeledImage, sortIndexes(1:numberToExtract));
	% Convert from integer labeled image into binary (logical) image.
	binaryImage = biggestBlob > 0;
catch ME
	errorMessage = sprintf('Error in function ExtractNLargestBlobs().\n\nError Message:\n%s', ME.message);
	fprintf(1, '%s\n', errorMessage);
	uiwait(warndlg(errorMessage));
    
end
end
end