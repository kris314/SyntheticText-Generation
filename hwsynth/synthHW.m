function synthHW(fontFolder, vocabFile, outFolder)
%Creates synthetic word images from handwritten fonts

%Parameters
numSamples=5; 	%num of samples per class(vocabulary word)
stdFVal = 20; 		%deviation of pixel intensity for foreground and background values
stdBVal = 7;

%read font files
fontFiles = dir(fontFolder);
cntr =1;
for i=3:length(fontFiles)
    fontPaths{cntr} = [fontFolder fontFiles(i).name];
    cntr = cntr + 1;    
end
cntr = cntr-1;

%read vocab file
fV = fopen(vocabFile,'r');
vocabData = textscan(fV,'%s');
fclose(fV);

startIdx = 1;
endIdx = numel(vocabData{1});

localFolder = outFolder;
tmpFolder = ['tmp/'];
mkdir(localFolder);
mkdir(tmpFolder);
mkdir(outFolder);
tmpFile=[tmpFolder num2str(startIdx) '.gif'];

fprintf('Running for array id:%f and end id:%f\n',startIdx,endIdx);
for i=startIdx:min(numel(vocabData{1}),endIdx)
    try
        tic
        fprintf('Printing %s %d:%d\n',vocabData{1}{i},i,numel(vocabData{1}));
        currText = vocabData{1}{i};
        currImgFolder = [localFolder num2str(i)];
        mkdir(currImgFolder);
        rFonts = randperm(cntr,min(numSamples,cntr));
        
        for j=1:numel(rFonts)
            %foreground value between 1-100 and background between 180-255
            meanFVal = randperm(100,1);
            meanBVal = randperm(75,1)+180;
            rVal = rand();
            
            %case insensitive data creation
            if(rVal<=0.4)
                currText=lower(currText);
            elseif(rVal>0.4 && rVal<=0.8 && numel(currText)>1)
                currText = [upper(currText(1)) lower(currText(2:end))];
            elseif(rVal>0.8)
                currText = upper(currText);
            end
            
            kernArray = randperm(8,1);
            strokeWidthArray = randperm(4,1);
            
            currKern = kernArray(1);
            currSW = strokeWidthArray(1);
            
            currImgPath = sprintf('%s%s%d_%d_%d.png',currImgFolder,filesep,rFonts(j),currKern,currSW);
            cmd = sprintf('convert -font "%s" -size x75 -kerning %d -strokewidth %d -stroke black -gravity center label:"%s" %s',...
                fontPaths{rFonts(j)},1,1,currText,tmpFile);
            [s,w]  = system(cmd);
            
            img = imread(tmpFile);
            
            %modify foreground and backgournd pixels
            [level EM] = graythresh(img);
            binImg = im2bw(img,level);
            [r c] = find(~binImg);
            sFIdx = find(img<=(level*255));
            sBIdx = find(img>(level*255));
            
            rF = floor(normrnd(meanFVal*ones(numel(sFIdx),1),stdFVal*ones(numel(sFIdx),1)));
            rB = floor(normrnd(meanBVal*ones(numel(sBIdx),1),stdBVal*ones(numel(sBIdx),1)));
            
            rFIdx = find(rF>255);
            rF(rFIdx) = 255;
            rFIdx = find(rF<0);
            rF(rFIdx) = 0;
            
            rBIdx = find(rB>255);
            rB(rBIdx) = 255;
            rBIdx = find(rB<0);
            rB(rBIdx) = 0;
            
            img(sFIdx) = rF;
            img(sBIdx) = rB;
            
            h = fspecial('gaussian',[3,3],2);
            img = imfilter(img,h,'replicate');
            
            imwrite(img,currImgPath,'png');
            
            %%%       Uncomment the below code for saving the normalized image
            %         img = imresize(img,[48,128]);
            %         if size(img, 3) > 1, img = rgb2gray(img); end;
            %         img = imresize(img, [48, 128]);
            %         img = single(img);
            %         s = std(img(:));
            %         img = img - mean(img(:));
            %         img = img / ((s + 0.0001) / 128.0);
            %         imwrite(img,currImgPath,'png');
        end
    catch err
        disp(err);
        delete(tmpFile);
    end
    toc
end

disp('Completed');
