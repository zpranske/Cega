addpath('C:\Users\Zachary_Pranske\Documents\GitHub\Cega\MATLAB');
addpath('C:\Users\Zachary_Pranske\Desktop\Datasets');

%movie = tiffreadVolume('C:\Users\Zachary_Pranske\Desktop\Datasets\2023-05-18 analysis GAD65\CEGA test\Substack (1-100-1).tif');
[fileName,pathLoc] = uigetfile('.tif','Select a tif stack to analyze','C:\Users\Zachary_Pranske\Desktop\Datasets\2023-05-18 analysis GAD65\CEGA test\');
fileLoc = fullfile(pathLoc,fileName);

%% Load the tif file
InfoImage=imfinfo(fileLoc);
mImage=InfoImage(1).Width;
nImage=InfoImage(1).Height;
NumberImages=length(InfoImage);
Vector=zeros(nImage,mImage,NumberImages,'uint16');
for i=1:NumberImages
   Vector(:,:,i)=imread(fileLoc,'Index',i);
end

%% Set Gain and Offset values, assuming read noise is negligible for exposition
Gain = 22.4; %From image metadata
Offset = 2200;
%% Use a prompt if user has custom data
% Gain = inputdlg('What is the Camera gain for this movie? (ADU/e-)');
% Offset = inputdlg('What is the Camera offset for this movie? (ADU)');
%% Tansform movie units from ADU to effective photons!
movie = (single(Vector)-Offset)/Gain; % make sure to convert tiffs from uint to single format!

ConnectivityThreshold = .5;
windowLength = 31;
sigmas = [1,1.5];
KLThreshold = 0.05;

[coordinates, filterMovies] = cega( movie, ConnectivityThreshold, ...
    windowLength, sigmas, KLThreshold);

%% Paint coordinates onto the final image to see how identification looks
x = coordinates(:,1);
y = coordinates(:,2);
t = coordinates(:,3);

imsz = size(movie);
xLow = x-1;
xHigh = x+1;
yLow = y-1;
yHigh = y+1;
xLow(xLow<1) = 1;
yLow(yLow<1) = 1;
xHigh(xHigh>imsz(1)) = imsz(1);
yHigh(yHigh>imsz(2)) = imsz(2);

% for built in implay
% make an rgb tensor
%outIm = repmat(filterMovies.KLM,[1 1 1 3]);
outIm = repmat(movie,[1 1 1 3]);
outIm = permute(outIm,[1 2 4 3]);
outIm = outIm/max(outIm(:))*255; % rescale to 8 bit
% draw red x's on implay movie
for ii = 1:length(x)
   outIm(xLow(ii):xHigh(ii),y(ii),:,t(ii)) = 0;
   outIm(xLow(ii):xHigh(ii),y(ii),1,t(ii)) = 255;
   outIm(x(ii),yLow(ii):yHigh(ii),:,t(ii)) = 0;
   outIm(x(ii),yLow(ii):yHigh(ii),1,t(ii)) = 255;
end
% convert to uint8 and run implay
implay(uint8(outIm));