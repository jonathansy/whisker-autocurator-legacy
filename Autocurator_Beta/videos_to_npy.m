function videos_to_npy(contacts, videoDir, saveDir)
  % Check existance
  if exist(videoDir) ~= 7
    error('Cannot find video directory')
  elseif exist(saveDir) ~= 7
    error('Cannot find saving directory')
  end
  samplePoleImage = 'C:\SuperUser\Code\ML_whisker_image_dev\samplePoleMat'

  % Establish number of trials in contacts and number of videos
  numTrials = length(contacts);
  vList = dir([videoDir '/*.mp4']); % Get list of mp4s
  videoList = {vList(:).name};
  numVideos = length(videoList);

  % Begin loop
  for i = 1:numTrials
    % Find indices of frames we need to curate
    labels = contacts{i}.labels;
    relevantIdx = find(labels == 2);
    % Skip trial if nothing to curate
    if isempty(relevantIdx)
      continue
    end

    % Find corresponding video
    trialNum = contacts{i}.trialNum;
    for j = 1:numVideos
      videoName = videoList{j};
      exprNum = '[0123456789]+.mp4';
      resultStr = regexp(videoName, exprNum, 'match'); %Should return #.mp4
      numStr = resultStr{1}(1:(end-4)); %Strip '.mp4' to leave just video number
      vidNumber = str2num(numStr);
      if vidNumber == trialNum
        fullVidName = [videoDir filesep videoName];
        break
      else
        continue
      end
    end
    
    % If for some reason no video, skip
    if isempty(fullVidName)
      continue
    end

    % Load with mmread
    videoArray = mmread(fullVidName);

    % Find pole location in video
    sPM = load(samplePoleImage); % Saved picture of pole
    samplePoleMat = sPM.samplePoleMat;
    testFrame = videoArray.frames(1500).cdata(:,:,1);
    corrPoints = normxcorr2(samplePoleMat, testFrame(:,:,1));
    [yCorr, xCorr] = find(corrPoints==max(corrPoints(:)));
    xPole = xCorr - (size(samplePoleMat, 2) /2);
    yPole = yCorr - (size(samplePoleMat, 1) /2);
    poleBox = [yPole-30, yPole+30, xPole-30, xPole+30];

    % Prep loop
    numRelFrames = numel(relevantIdx);
    finalMat = zeros(numRelFrames,61);
    finalMat = repmat(finalMat, 1,1,61);

    % Frame loop
    for k = 1:numRelFrames
      curIdx = relevantIdx(k);
      curFrame = videoArray.frames(curIdx).cdata(:,:,1);
      nFrameMat = curFrame((poleBox(1)):(poleBox(2)),(poleBox(3)):(poleBox(4)));
      finalMat(k,:,:) = nFrameMat;
    end

    % Save as npy file
    saveName = videoName(1:end-4);
    saveName = [saveDir filesep saveName '_dataset.npy'];
    writeNPY(finalMat, saveName)
    
    % Clear variables
    videoArray = [];
    finalMat = [];
    fullVidName = [];
    videoName = [];
  end