function pleasure_fmri_task_main(SID, SubjNum, type, varargin)
 
%% SETUP : Basic parameters
 
global theWindow W H window_ratio  %window property
global lb rb scale_W scale_H anchor_lms  %rating scale
global bgcolor white orange red  %color
 
basedir = pwd;
cd(basedir); 
addpath(genpath(basedir));
 
explain = false;
practice = false;
run = false;
USE_EYELINK = false;
USE_BIOPAC = false;
 
%% PARSING VARARGIN
 
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % functional commands
            case {'explain'}
                explain = true;
            case {'practice'}
                practice = true;
            case {'run'}
                run = true;
%             case {'savedir'}
%                 savedir = varargin{i+1};
            case {'eyelink', 'eye', 'eyetrack'}
                USE_EYELINK = true;
            case {'biopac'}
                USE_BIOPAC = true;
                channel_n = 3;
                biopac_channel = 0;
                ljHandle = BIOPAC_setup(channel_n); % BIOPAC SETUP
        end
    end
end
 
%% SETUP : Check subject information & load run order
    
SubjRun = input('\nRun number? : ');
 
%% SETUP : Save data according to subject information
 
savedir = fullfile(basedir, 'Data');
 
nowtime = clock;
SubjDate = sprintf('%.2d%.2d%.2d', nowtime(1), nowtime(2), nowtime(3));
 
data.subject = SID;
data.datafile = fullfile(savedir, [SubjDate, '_', SID, '_subj', sprintf('%.3d', SubjNum), ...
    '_run', sprintf('%.2d', SubjRun), '.mat']);
data.version = 'Pleasure_v1_08-27-2018_Cocoanlab';
data.starttime = datestr(clock, 0);
data.starttime_getsecs = GetSecs;
 
% if the same file exists, break and retype subject info
if exist(data.datafile, 'file')
    fprintf('\n ** EXSITING FILE: %s %s **', data.subject, SubjDate);
    cont_or_not = input(['\nYou type the run number that is inconsistent with the data previously saved.', ...
        '\nWill you go on with your run number that typed just before?', ...
        '\n1: Yes, continue with typed run number.  ,   2: No, it`s a mistake. I`ll break.\n:  ']);
    if cont_or_not == 2
        error('Breaked.')
    elseif cont_or_not == 1
        save(data.datafile, 'data');
    end
else
    save(data.datafile, 'data');
end
 
%% SETUP : Create paradigm according to subject information
 
S.type = type;
% S.dur = 15*60 - 10; % 15 mins - 10 secs for disdaq
S.dur = 30;
 
S.changecolor = [10:60:S.dur];
changecolor_jitter = randi(10, 1, numel(S.changecolor));
S.changecolor = S.changecolor + changecolor_jitter;
S.changetime = 1; % duration of color change : 1 sec
 
data.dat.type = S.type;
data.dat.duration = S.dur;
data.dat.changecolor = S.changecolor;
data.dat.changetime = S.changetime;
 
%% SETUP: Save eyelink filename according to subject information
 
% need to be revised when the eyelink is here.
if USE_EYELINK
    
    edf_filename = ['E_' SID '_' SubjNum]; % name should be equal or less than 8
    edfFile = sprintf('%s.EDF', edf_filename);
    eyelink_main(edfFile, 'Init');
    
    status = Eyelink('Initialize');
    if status
        error('Eyelink is not communicating with PC. It is okay baby.');
    end
    Eyelink('Command', 'set_idle_mode');
    waitsec_fromstarttime(GetSecs, .5);
  
end
 
%% SETUP : Screen
 
bgcolor = 100;
window_ratio = 3;
 
screens = Screen('Screens');
window_num = screens(1);
Screen('Preference', 'SkipSyncTests', 1);
screen_mode = 'test';
window_info = Screen('Resolution', window_num);
switch screen_mode
    case 'full'
        window_rect = [0 0 window_info.width window_info.height]; % full screen
        fontsize = 32;
    case 'semifull'
        window_rect = [0 0 window_info.width-100 window_info.height-100]; % a little bit distance
    case 'middle'
        window_rect = [0 0 window_info.width/2 window_info.height/2];
    case 'small'
        window_rect = [0 0 400 300]; % in the test mode, use a little smaller screen
        fontsize = 10;
    case 'test'
        window_rect = [0 0 window_info.width window_info.height]/window_ratio;
        fontsize = 20;
end
 
% size
W = window_rect(3); % width
H = window_rect(4); % height
 
lb = W*(1/8); % rating scale left bounds 1/8
rb = W*(7/8); % rating scale right bounds 7/8
 
scale_W = W*0.1;
scale_H = H*0.1;
 
anchor_lms = [W/2-0.01*(W/2-lb) W/2-0.06*(W/2-lb) W/2-0.18*(W/2-lb) W/2-0.35*(W/2-lb) W/2-0.5*(W/2-lb);
    W/2+0.01*(W/2-lb) W/2+0.06*(W/2-lb) W/2+0.18*(W/2-lb) W/2+0.35*(W/2-lb) W/2+0.5*(W/2-lb)];
%W/2-lb = rb-W/2
 
% color
% bgcolor = 50;
white = 255;
red = [158 1 66];
orange = [255 164 0];
 
% font
font = 'NanumBarunGothic';
Screen('Preference', 'TextEncodingLocale', 'ko_KR.UTF-8');
 
%% PROMPT SETUP:
rating_types.prompts_ex = ...
    {
    '���ݺ��� ������ ���۵˴ϴ�. ����, ������ �����ϱ⿡ �ռ� �� ô���� ���� ������ �����ϰڽ��ϴ�.\n\n�����ڴ� ��� �غ� �Ϸ�Ǹ� ��ư�� �����ֽñ� �ٶ��ϴ�.', ...
   '�� ���� : �����ڴ� �� ����� ���� ����� ������ ��, �����̽��ٸ� �����ֽñ� �ٶ��ϴ�.', ...
    '�� ���� : �����ڴ� ����� �� ����� ������ ��, ������ ������ ��ư�� �����ֽñ� �ٶ��ϴ�.', ...
    };
run_start_prompt = double('\n�����ڴ� ��� ���� �� �غ�Ǿ����� üũ���ּ��� (Biopac, Eyelink, ���).\n\n��� �غ�Ǿ�����, �����̽��ٸ� �����ּ���.');
run_ready_prompt = double('�����ڰ� �غ�Ǿ�����, �̹�¡�� �����մϴ� (s).');
% run_end_prompt = double('���ϼ̽��ϴ�. ��� ����� �ּ���.');
 
%% Start : Screen
sca
theWindow = Screen('OpenWindow', window_num, bgcolor, window_rect); % start the screen
%Screen('TextFont', theWindow, font);
Screen('TextSize', theWindow, fontsize);
 
Screen(theWindow, 'FillRect', bgcolor, window_rect); % Just getting information, and do not show the scale.
Screen('Flip', theWindow);
HideCursor;
 
%% Start
 
try
%% (Explain) Continuous
    
    % Explain scale with visualization
    
    if explain
        
        x = W/2; %center
        y = H*(3/4); %center*(3/2)
        
        while true % Button
            DrawFormattedText(theWindow, double(rating_types.prompts_ex{1}), 'center', H*(1/4), white, [], [], [], 2);
            Screen('Flip', theWindow);
            
            [~,~,button] = GetMouse(theWindow);
            if button(1) == 1
                break
            end
        end
        
        while true % Space
            DrawFormattedText(theWindow, double(rating_types.prompts_ex{2}), 'center', H*(1/4), white, [], [], [], 2);
            Screen('DrawLine', theWindow, white, lb, H*(3/4), rb, H*(3/4), 4); %rating scale
            % penWidth: 0.125~7.000
            for i = 2:5
                Screen('DrawLine', theWindow, white, anchor_lms(1,i), H*(3/4)-scale_H/4, anchor_lms(1,i), H*(3/4)+scale_H/4, 2);
                Screen('DrawLine', theWindow, white, anchor_lms(2,i), H*(3/4)-scale_H/4, anchor_lms(2,i), H*(3/4)+scale_H/4, 2);
            end
            DrawFormattedText(theWindow, double('���谨'), lb-70, H*(3/4)+10, white);
            DrawFormattedText(theWindow, double('�谨'), rb+20, H*(3/4)+10, white);
            DrawFormattedText(theWindow, double('�߸�'), W/2-20, H*(3/4)+scale_H/2*1.5);
            Screen('DrawLine', theWindow, white, W/2, H*(3/4)-scale_H/3, W/2, H*(3/4)+scale_H/3, 6);
            Screen('DrawLine', theWindow, white, lb, H*(3/4)-scale_H/2, lb, H*(3/4)+scale_H/2, 6);
            Screen('DrawLine', theWindow, white, rb, H*(3/4)-scale_H/2, rb, H*(3/4)+scale_H/2, 6);
            
            %         DrawFormattedText(theWindow, double('���� �������� ����'), anchor_lms(1,1)-scale_W/5, H*(3/4)+scale_H/4, white,2,[],[],1);
            DrawFormattedText(theWindow, double('����'), anchor_lms(1,2)-scale_W/5, H*(3/4)+scale_H/2, white, [],[],[],1);
            DrawFormattedText(theWindow, double('�߰�'), anchor_lms(1,3)-scale_W/5, H*(3/4)+scale_H/2, white, [],[],[],1);
            DrawFormattedText(theWindow, double('����'), anchor_lms(1,4)-scale_W/5, H*(3/4)+scale_H/2, white, [],[],[],1);
            DrawFormattedText(theWindow, double('�ſ� ����'), anchor_lms(1,5)-scale_W/5, H*(3/4)+scale_H/2, white, 2,[],[],1);
            
            %         DrawFormattedText(theWindow, double('���� �������� ����'), anchor_lms(2,1), H*(3/4)+scale_H/4, white,2,[],[],1);
            DrawFormattedText(theWindow, double('����'), anchor_lms(2,2)-scale_W/5, H*(3/4)+scale_H/2, white, [],[],[],1);
            DrawFormattedText(theWindow, double('�߰�'), anchor_lms(2,3)-scale_W/5, H*(3/4)+scale_H/2, white, [],[],[],1);
            DrawFormattedText(theWindow, double('����'), anchor_lms(2,4)-scale_W/5, H*(3/4)+scale_H/2, white, [],[],[],1);
            DrawFormattedText(theWindow, double('�ſ� ����'), anchor_lms(2,5)-scale_W/5, H*(3/4)+scale_H/2, white, 2,[],[],1);
            
            Screen('Flip', theWindow);
            
            [~,~,keyCode] = KbCheck;
            if keyCode(KbName('space')) == 1
                break
            elseif keyCode(KbName('q')) == 1
                abort_experiment('manual');
            end
        end
        
    end
    
    %% (Practice) Continuous
    
    if practice
        
        x = W/2; %center
        y = H*(3/4); %center*(3/2)
        SetMouse(x,y)
        
        while true % Space
            DrawFormattedText(theWindow, double(rating_types.prompts_ex{3}), 'center', H*(1/4), white, [], [], [], 2);
            
            [x,~,button] = GetMouse(theWindow);
            [~,~,keyCode] = KbCheck;
            
            if x < lb
                x = lb;
            elseif x > rb
                x = rb;
            end
            
            if button(1) == 1
                break
            elseif keyCode(KbName('q')) == 1
                abort_experiment('manual');
            end
            
            
            Screen('DrawLine', theWindow, white, lb, H*(3/4), rb, H*(3/4), 4); %rating scale
            % penWidth: 0.125~7.000
            Screen('DrawLine', theWindow, white, W/2, H*(3/4)-scale_H/3, W/2, H*(3/4)+scale_H/3, 6);
            Screen('DrawLine', theWindow, white, lb, H*(3/4)-scale_H/2, lb, H*(3/4)+scale_H/2, 6);
            Screen('DrawLine', theWindow, white, rb, H*(3/4)-scale_H/2, rb, H*(3/4)+scale_H/2, 6);
            Screen('DrawLine', theWindow, orange, x, H*(3/4)-scale_H/1.5, x, H*(3/4)+scale_H/1.5, 6); %rating bar
            Screen('Flip', theWindow);
            
        end
        
    end
    
    %% (Main) Continuous
    
    if run
        
        while true % Start, Space
            DrawFormattedText(theWindow, double(run_start_prompt), 'center', 100, white, [], [], [], 2);
            Screen('Flip', theWindow);
            
            [~,~,keyCode] = KbCheck;
            if keyCode(KbName('space')) == 1
                break
            elseif keyCode(KbName('q')) == 1
                abort_experiment('manual');
            end
        end
        
        
        while true % Ready, s
            DrawFormattedText(theWindow, double(run_ready_prompt), 'center', 'center', white, [], [], [], 2);
            Screen('Flip', theWindow);
            
            [~,~,keyCode] = KbCheck;
            if keyCode(KbName('s')) == 1
                break
            elseif keyCode(KbName('q')) == 1
                abort_experiment('manual');
            end
        end
 
        %% For disdaq : 10 secs --> NEED MODIFY??
        % For disdaq ("�����մϴ١�") : 4 secs
        data.runscan_starttime = GetSecs;
        Screen(theWindow, 'FillRect', bgcolor, window_rect);
        DrawFormattedText(theWindow, double('�����մϴ١�'), 'center', 'center', white, [], [], [], 1.2);
        Screen('Flip', theWindow);
        waitsec_fromstarttime(data.runscan_starttime, 4);
        
        [~,~,keyCode] = KbCheck;
        if keyCode(KbName('q')) == 1
            abort_experiment('manual');
        end
        
        % For disdaq (blank / EYELINK & BIOPAC START) : 6 secs
        Screen(theWindow,'FillRect',bgcolor, window_rect);
        Screen('Flip', theWindow);
        
        if USE_EYELINK
            Eyelink('StartRecording');
            data.dat.eyelink_starttime = GetSecs; % eyelink timestamp
            Eyelink('Message','Task Run start');
        end
        
        if USE_BIOPAC
            data.dat.biopac_starttime = GetSecs; % biopac timestamp
            BIOPAC_trigger(ljHandle, biopac_channel, 'on');
            waitsec_fromstarttime(data.dat.biopac_starttime, 0.6);
            BIOPAC_trigger(ljHandle, biopac_channel, 'off');
        end
        
        waitsec_fromstarttime(data.runscan_starttime, 10);  % 4+6      
        
        %% Continuous rating
        
        run_start_t = GetSecs;
        data.dat.saverun_timestamp = run_start_t;
        
        rec_i = 0;
        x = W/2; %center
        y = H*(3/4); %center*(3/2)
        SetMouse(x,y)
        
        while GetSecs - run_start_t < S.dur
            
            rec_i = rec_i + 1;
            [x,~,button] = GetMouse(theWindow);            
            if x < lb
                x = lb;
            elseif x > rb
                x = rb;
            end
            
            Screen('DrawLine', theWindow, white, lb, H*(3/4), rb, H*(3/4), 4); %rating scale
            % penWidth: 0.125~7.000
            Screen('DrawLine', theWindow, white, W/2, H*(3/4)-scale_H/3, W/2, H*(3/4)+scale_H/3, 6);
            Screen('DrawLine', theWindow, white, lb, H*(3/4)-scale_H/2, lb, H*(3/4)+scale_H/2, 6);
            Screen('DrawLine', theWindow, white, rb, H*(3/4)-scale_H/2, rb, H*(3/4)+scale_H/2, 6);
            Screen('DrawLine', theWindow, orange, x, H*(3/4)-scale_H/1.5, x, H*(3/4)+scale_H/1.5, 6); %rating bar
            
            run_cur_t = GetSecs;
            data.dat.run_time_fromstart(rec_i,1) = run_cur_t-run_start_t;
            data.dat.run_cont_rating(rec_i,1) = (x-W/2)/(rb-lb).*2;
            data.dat.run_changecolor_response(rec_i,1) = button(1);
            
            % Behavioral task
            if any(S.changecolor <= run_cur_t - run_start_t & run_cur_t - run_start_t <= S.changecolor + S.changetime) % It takes 1 sec from the S.changecolor
                Screen('DrawLine', theWindow, red, x, H*(3/4)-scale_H/1.5, x, H*(3/4)+scale_H/1.5, 6); %rating bar turns in red
                data.dat.changecolor_stim(rec_i) = 1;
            else
                Screen('DrawLine', theWindow, orange, x, H*(3/4)-scale_H/1.5, x, H*(3/4)+scale_H/1.5, 6); %rating bar returns to its own color
                data.dat.changecolor_stim(rec_i) = 0;
            end
            
            [~,~,keyCode] = KbCheck;
            if keyCode(KbName('q')) == 1
                abort_experiment('manual');
            end
            
            Screen('Flip', theWindow);
            
            % save data every 1 min
            for n = 1:15
                if GetSecs - data.dat.saverun_timestamp == 60*n
                    save(data.datafile, '-append', 'data')
                end
            end
            
        end
        
        data.dat.run_dur = GetSecs - run_start_t;
        
        if USE_EYELINK
            Eyelink('Message','Run End');
        end
   
        %     while true % End, Space
        %         DrawFormattedText(theWindow, double(run_end_prompt), 'center', H*(1/4), white, [], [], [], 2);
        %         Screen('Flip', theWindow);
        %
        %         [~,~,keyCode] = KbCheck;
        %         if keyCode(KbName('space')) == 1
        %             break
        %         elseif keyCode(KbName('q')) == 1
        %             abort_experiment('manual');
        %         end
        %     end
        
        %% MAIN : Postrun questionnaire
        
        all_start_t = GetSecs;
        data.dat.postrun_rating_timestamp = all_start_t;
        
        msgtxt = [num2str(SubjRun) '��° ������ �������ϴ�.\n��� �� �������� ���õ� ���Դϴ�. �����ںв����� ��ٷ��ֽñ� �ٶ��ϴ�.'];
        msgtxt = double(msgtxt); 
        DrawFormattedText(theWindow, msgtxt, 'center', 'center', white, [], [], [], 2);
        Screen('Flip', theWindow);
        waitsec_fromstarttime(all_start_t, 5)
        
        Screen(theWindow, 'FillRect', bgcolor, window_rect);
        Screen('Flip', theWindow);
        
        if USE_EYELINK
            Eyelink('Message','Postrun Start');
        end
        
        [~,~,keyCode] = KbCheck;
        if keyCode(KbName('q')) == 1
            abort_experiment('manual');
        end
        
        x = W/2; %center
        y = H*(3/4); %center*(3/2)
        SetMouse(x,y)
        
        postrun_start_t = GetSecs;
        rec_i = 0;
 
        [x,~,button] = GetMouse(theWindow);
        
        while true
            rec_i = rec_i + 1;
            [x,~,button] = GetMouse(theWindow);
            if x < lb
                x = lb;
            elseif x > rb
                x = rb;
            end
            
            msgtxt = '�ش� �ڱ��� �󸶳� ���Ҵ���/�Ⱦ������� ���� �����ּ���.';
            DrawFormattedText(theWindow, double(msgtxt), 'center', H*(1/4), white);
            Screen('DrawLine', theWindow, white, lb, H*(3/4), rb, H*(3/4), 4); %rating scale
            % penWidth: 0.125~7.000
            Screen('DrawLine', theWindow, white, W/2, H*(3/4)-scale_H/3, W/2, H*(3/4)+scale_H/3, 6);
            DrawFormattedText(theWindow, double('����'), lb-50, H*(3/4)+10, white);
            Screen('DrawLine', theWindow, white, lb, H*(3/4)-scale_H/2, lb, H*(3/4)+scale_H/2, 6);
            DrawFormattedText(theWindow, double('����'), rb+20, H*(3/4)+10, white);
            Screen('DrawLine', theWindow, white, rb, H*(3/4)-scale_H/2, rb, H*(3/4)+scale_H/2, 6);
            Screen('DrawLine', theWindow, orange, x, H*(3/4)-scale_H/1.5, x, H*(3/4)+scale_H/1.5, 6); %rating bar
            Screen('Flip', theWindow);
            
            if button(1)
                while button(1)
                    [~,~,button] = GetMouse(theWindow);
                end
                break
            end
        end
        
        % Freeze the screen 0.5 second with red line if overall type
        freeze_t = GetSecs;
        while true
            msgtxt = '�ش� �ڱ��� �󸶳� ���Ҵ���/�Ⱦ������� ���� �����ּ���.';
            DrawFormattedText(theWindow, double(msgtxt), 'center', H*(1/4), white);
            Screen('DrawLine', theWindow, white, lb, H*(3/4), rb, H*(3/4), 4); %rating scale
            % penWidth: 0.125~7.000
            Screen('DrawLine', theWindow, white, W/2, H*(3/4)-scale_H/3, W/2, H*(3/4)+scale_H/3, 6);
            DrawFormattedText(theWindow, double('����'), lb-50, H*(3/4)+10, white);
            Screen('DrawLine', theWindow, white, lb, H*(3/4)-scale_H/2, lb, H*(3/4)+scale_H/2, 6);
            DrawFormattedText(theWindow, double('����'), rb+20, H*(3/4)+10, white);
            Screen('DrawLine', theWindow, white, rb, H*(3/4)-scale_H/2, rb, H*(3/4)+scale_H/2, 6);
            
            Screen('DrawLine', theWindow, red, x, H*(3/4)-scale_H/1.5, x, H*(3/4)+scale_H/1.5, 6);
            Screen('Flip', theWindow);
            freeze_cur_t = GetSecs;
            if freeze_cur_t - freeze_t > 0.5
                break
            end
        end
        
        postrun_cur_t = GetSecs;
        data.dat.postrun_time_fromstart(rec_i,1) = postrun_cur_t - postrun_start_t;
        data.dat.postrun_cont_rating(rec_i,1) = (x-W/2)/(rb-lb).*2;        
        
        % Move to the next
        msgtxt = double('������ �������ϴ�. ��ø� ������ּ���.');
        DrawFormattedText(theWindow, msgtxt, 'center', 'center', white);
        Screen('Flip', theWindow);
        WaitSecs(5);
        
         if USE_EYELINK
            Eyelink('Message','Postrun End');
            eyelink_main(edfFile, 'Shutdown');
        end
        if USE_BIOPAC
            data.dat.biopac_endtime = GetSecs; % biopac timestamp
            BIOPAC_trigger(ljHandle, biopac_channel, 'on');
            waitsec_fromstarttime(data.dat.biopac_endtime, 0.1);
            BIOPAC_trigger(ljHandle, biopac_channel, 'off');
        end
        
        all_end_t = GetSecs;
        data.dat.postrun_dur = all_end_t - all_start_t;
        
        save(data.datafile, '-append', 'data');
        
        ShowCursor;
        sca;
        Screen('CloseAll');
        
    end
    %% Closing screen
    
    % while true % Space
    %
    %     [~,~,keyCode] = KbCheck(Exp_key);
    %     if keyCode(KbName('space'))
    %         while keyCode(KbName('space'))
    %             [~,~,keyCode] = KbCheck(Exp_key);
    %         end
    %         break
    %     end
    %
    %     if keyCode(KbName('q')) == 1
    %         abort_experiment('manual');
    %         break
    %     end
    %
    %     msgtxt = [num2str(SubjRun) '��° ������ �������ϴ�.\n������ ��ġ����, �����ڴ� �����̽��ٸ� �����ֽñ� �ٶ��ϴ�.'];
    %     msgtxt = double(msgtxt); % korean to double
    %     DrawFormattedText(theWindow, msgtxt, 'center', 'center', white, [], [], [], 2);
    %     Screen('Flip', theWindow);
    %
    % end
    %
    % Screen('CloseAll');
    %
    % if exist('t', 'var') && ~isempty(t); fclose(t); end
    % if exist('r', 'var') && ~isempty(r); fclose(r); end
    
catch err
    % ERROR
    disp(err);
    for i = 1:numel(err.stack)
        disp(err.stack(i));
    end
    %     fclose(t);
    %     fclose(r);  % Q??
    abort_experiment('error');
end
end