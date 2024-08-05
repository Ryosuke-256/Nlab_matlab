function [res1, res2] = Exp1_Onetrial(sv1, sv2, window ,xCenter, yCenter)

%%------------initialization------------------
KbName('UnifyKeyNames');
myKeyCheck;

%default key
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');

res1 = 0;
res2 = 0;

adjust = 270;

%%-------------experient------------------

lefttexture = Screen('MakeTexture', window, sv1);
leftpos = CenterRectOnPointd(Screen('Rect', lefttexture), ...
    xCenter/2 + adjust, ...
    yCenter...
    );
Screen('DrawTexture', window, lefttexture, [], leftpos);

righttexture = Screen('MakeTexture', window, sv2);
rightpos = CenterRectOnPointd(Screen('Rect', righttexture), ...
    xCenter/2*3 - adjust, ...
    yCenter...
    );
Screen('DrawTexture', window, righttexture, [], rightpos);

Screen('Flip',window);

respToBeMade = true;
%キーボードが押された時の処理
while respToBeMade == true
    KbWait;
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyCode(escapeKey)
        sca;
        return;
    elseif keyCode(leftKey)
        res1 = res1 + 1;        
        respToBeMade = false; 
    elseif keyCode(rightKey)
        res2 = res2 + 1;
        respToBeMade = false; 
    end
end
Screen('Close', lefttexture); 
Screen('Close', righttexture); 
KbReleaseWait;