% Clear the workspace
close all;
clear;
sca;

% Setup PTB with some default values
%PsychDefaultSetup(2);

% Seed the random number generator
rng('default')

% Set the screen number to the external secondary monitor if there is one
% connected
%screenNumber = max(Screen('Screens'));
screenNumber = 0;

% Define black, white and greya
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

%SetResolution(screenNumber,4096,2160);
% Open the screen
%[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [50 50 700 700], 32, 2);
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey,[50 50 700 700]);

PsychImaging('PrepareConfiguration');
% PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set the text size
Screen('TextSize', window, 60);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%PsychImaging('PrepareConfiguration');
%PsychImaging('AddTask', 'General', 'EnableNative10BitFramebuffer');

%oldResolution=Screen('Resolution', screenNumber,4096,2160);

%resoration 4096, 2160
%Screen('Resolution', screenNumber,4096,2160);
%SetResolution(screenNumber,4096,2160);
%Screen('ConfigureDisplay',setting,screenNumber,outputId [,newwidth][,newheight][,newHz][,newX][,newY]);
%AdditiveBlendingForLinearSuperpositionTutorial('Native10Bit')

% Set maximum priority level
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);
isSupported = PsychHDR('Supported');
%---------------------------------------------------------------------
%                           csv road
%---------------------------------------------------------------------
SubName = input('Name? ', 's'); % 名前をたずねる
if isempty(SubName) % 名前の入力がなかったらプログラムを終了
    return;
end
% 出力ファイルの上書き確認を行う
SaveFileName=['experiment/result/',SubName '.csv']; % 出力ファイル名
if exist(SaveFileName, 'file') % すでに同じ名前のファイルが存在していないかの確認
    resp=input([SaveFileName 'はすでに存在します。上書きをしてよい場合は y を入力してエンターキーを押してください。'], 's');
    if ~strcmp(resp,'y') 
        disp('プログラムを強制終了しました。')
        return
    end
end

%---------------------------------------------------------------------
%                           image road
%---------------------------------------------------------------------

%imageFolder = 'experiment/images/';
imageFolder = 'vspy/outimg/digital_rgb';

% 画像フォルダ内の画像ファイルを取得
imageFiles = dir(fullfile(imageFolder, '*.mat')); % 画像フォーマットに応じて変更

% 画像ファイルの数を取得
numImages = numel(imageFiles);

randomOrder = randperm(numImages);
firstTen = randomOrder(1:10);%順応
randomOrder = [randomOrder, firstTen];
disp(randomOrder);
trialnum=length(randomOrder);

%size ofimage
imgRatio = 0.48250612745; 

%------------------------------------------------
%scale bar
%------------------------------------------------
question = '';
lowerText = '0';
upperText = '200';
pixelsPerPress = 4;
lineLength = 500; % pixels
halfLength = lineLength/2; 
divider = lineLength/200; % for a rating of 1:10

down_posision=500;

baseRect = [0 0 10 30]; % size of slider
LineX = xCenter;
LineY = yCenter;

rectColor = [0 0 0]; % color for slider
lineColor = [0 0 0]; % color for line
textColor = [0 0 0]; % color for text


%Screen('TextFont',w, 'Helvetica');  % font parameters
%Screen('TextSize',w, 16);
%Screen('TextStyle', w, 0);
%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------
KbName('UnifyKeyNames');
% a exit/reset key
escapeKey = KbName('ESCAPE');

%gaibu key
%leftKey = KbName('4');
%rightKey = KbName('6');
%downKey = KbName('2');

%default key
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
downKey = KbName('DownArrow');

enterKey = KbName('Return');


%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------
Fid = fopen(SaveFileName, 'wt');

respToBeMade = true;

% Animation loop: we loop for the total number of trials
for trial = 1:trialnum

    % Cue to determine whether a response has been made

    if trial == 1
        DrawFormattedText(window, 'Press Any Key To Begin',...
            'center', 'center', black);
        Screen('Flip', window);
        KbStrokeWait;
    end

   respToBeMade = true;
   imgname=fullfile(imageFolder, imageFiles(randomOrder(trial)).name);

   while respToBeMade == true

        % Draw image
        img = load(imgname).digital_rgb;
        %scaledImg = imresize(img, imgRatio); 
        texture = Screen('MakeTexture', window, img);
        Screen('DrawTexture', window, texture);
        
        %scaleber
        centeredRect = CenterRectOnPointd(baseRect, LineX, LineY+down_posision);

        currentRating = ((LineX - xCenter) +  halfLength)/divider;  %
        %ratingText = num2str(currentRating); % to make this display whole numbers, use "round(currentRating)"
        ratingresult = currentRating;

        %DrawFormattedText(window, ratingText ,'center', (yCenter+down_posision+100), textColor, [],[],[],5); % display current rating 
        %DrawFormattedText(window, question ,'center', (yCenter-100), textColor, [],[],[],5);

        Screen('DrawLine', window,  lineColor, (xCenter+halfLength ), (yCenter+down_posision),(xCenter-halfLength), (yCenter+down_posision),1);
        Screen('DrawLine', window,  lineColor, (xCenter+halfLength ), (yCenter +10+down_posision), (xCenter+halfLength), (yCenter-10+down_posision), 1);
        Screen('DrawLine', window,  lineColor, (xCenter-halfLength ), (yCenter+10+down_posision), (xCenter- halfLength), (yCenter-10+down_posision), 1);
        Screen('DrawLine', window,  lineColor, (xCenter), (yCenter+10+down_posision), (xCenter), (yCenter-10+down_posision), 1);

        %Screen('DrawText', window, lowerText, (xCenter-halfLength-6), (yCenter+down_posision+13),  textColor);
        %Screen('DrawText', window, upperText , (xCenter+halfLength-13) , (yCenter+down_posision+13), textColor);
            Screen('FillRect', window, rectColor, centeredRect);
            
        
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
            ShowCursor;
            sca;
            if exist('Fid', 'var') % ファイルを開いていたら閉じる。
                fclose(Fid);
                disp('fclose');
            end
            return
        elseif keyCode(downKey)
            StopPixel_M = ((LineX - xCenter) + halfLength)/divider; % for a rating of between 0 and 10. Tweak this as necessary.
            response = StopPixel_M;
            respToBeMade = false;                   
        elseif keyCode(leftKey)
            LineX = LineX - pixelsPerPress;
        elseif keyCode(rightKey)
            LineX = LineX + pixelsPerPress;
        end
        
        if LineX < (xCenter-halfLength)
            LineX = (xCenter-halfLength);
        elseif LineX > (xCenter+halfLength)
            LineX = (xCenter+halfLength);
        end
        
        if LineY < 0
            LineY = 0;
        elseif LineY > (yCenter+10)
            LineY = (yCenter+10);
        end
        
        Screen('Flip', window);
        Screen('Close', texture); 
   end

   %参照刺激とテスト刺激の入れ替え

   currenttime=datetime('now','TimeZone','local','Format','yyyy-MM-dd-HH-mm-ss.SSS');
   fprintf(Fid, '%d,%s,%f,%s\n', trial/2, imgname,ratingresult,currenttime);
   LineX = xCenter;
   LineY = yCenter;
   
   Screen('Flip', window);
   WaitSecs(1);
end

%close file
fclose(Fid);

DrawFormattedText(window, 'Experiment Finished \n\n Press Any Key To Exit',...
    'center', 'center', black);
Screen('Flip', window);
KbStrokeWait;
sca;