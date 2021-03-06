function out = oct_ecg_pulsatility_run(job)
% At this point, the folder contains a list of dat and mat files
% respectively containing acquisition information and data. This module
% will concatenate the acquisition info.
%_______________________________________________________________________________
% Copyright (C) 2012 LIOM Laboratoire d'Imagerie Optique et Mol�culaire
%                    �cole Polytechnique de Montr�al
%_______________________________________________________________________________

rev = '$Rev$'; %#ok

% Reference from previous computation.
OCTmat=job.OCTmat;
save_figures=job.save_figures;
save_data=fullfile(job.pulse_data_dir{1},'vessel.csv');
fid = fopen(save_data, 'w');
fprintf(fid,'Name, Mean, Median, Std, Max, Min\n');

% Loop over acquisitions
for acquisition=1:size(OCTmat,1)
    try
    load(OCTmat{acquisition});
    
    % If we save results, then they shoudl be saved locally to the data
    if save_figures
        dir_fig = fullfile(OCT.output_dir,'fig');
        if ~exist(dir_fig,'dir'),mkdir(dir_fig);end
    end
    % This reconstruction only works if the ECG data is recorded and we
    % have a 2D ramp type
    if( OCT.acqui_info.ramp_type == 1)
        
        % Reconstruction paramters to save in recons_info structure.
        acqui_info=OCT.acqui_info;
        recons_info = OCT.recons_info;
        
        %% Initialize 3D volume and average grid, it is a handle class to be able to pass across functions
        vol=C_OCTVolume(recons_info.size);
        vol.openint16(recons_info.ecg_recons.filename);
        
        % put image of first frame
        h = figure;
        maximize_figure(h, acqui_info);
        % Font Sizes
        titleFontSize   = 14;
        axisFontSize    = 16;
        labelFontSize   = 18;
        
        subplot(1,2,1)
        load doppler_color_map.mat
        colormap(doppler_color_map);
        
        % build z, r axis to display scaled data //EGC
        rAxis = 0:recons_info.step(1):recons_info.step(1)*(recons_info.size(1) - 1);
        zAxis = 0:recons_info.step(2):recons_info.step(2)*(recons_info.size(2) - 1);
        
        % Prompt user to choose the ROI that contains a vessel
        e=imagesc(zAxis,rAxis,squeeze(vol.data(:,:,1)));
        title('Choose an ROI containing a vessel','FontSize',titleFontSize,'interpreter','none')
        set(gca,'FontSize',axisFontSize)
        xlabel([recons_info.type{2} ' [\mum]'],'FontSize',labelFontSize);
        ylabel([recons_info.type{1} ' [\mum]'],'FontSize',labelFontSize);
        mask = roipoly;
       
        vessel_time_course=zeros(1,size(vol.data,3));
        for i=1:size(vol.data,3)
            tmp=squeeze(vol.data(:,:,i));
            vessel_time_course(i) = mean(tmp(mask));
        end
        % Normalize to scale
        vessel_time_course=vessel_time_course/double(intmax('int16'))*(vol.max_val-vol.min_val)+vol.min_val;
        
        % Build time axis (ms) //EGC
        tAxis = 1e-3*(0:recons_info.dt_us:recons_info.dt_us*(recons_info.size(3) - 1));
        
        % Refresh display with correct orientation of B-scan //EGC
        subplot(1,2,1)
        e=imagesc(rAxis,zAxis,squeeze(vol.data(:,:,1))');
        title([recons_info.type{1} ' Slice'],'FontSize',titleFontSize,'interpreter','none')
        set(gca,'FontSize',axisFontSize)
        ylabel([recons_info.type{2} ' [\mum]'],'FontSize',labelFontSize);
        xlabel([recons_info.type{1} ' [\mum]'],'FontSize',labelFontSize);
        
        subplot(1,2,2)
        plot(tAxis, vessel_time_course);
        title(OCT.acqui_info.base_filename,'FontSize',titleFontSize,'interpreter','none')
        set(gca,'FontSize',axisFontSize)
        xlabel('Time in cardiac cycle [ms]','FontSize',labelFontSize);
        ylabel([recons_info.type{1} ' Speed [mm/s]'],'FontSize',labelFontSize);
        xlim([min(tAxis) max(tAxis)]);
                
        if (save_figures)
            % filen = fullfile(dir_fig,['ROI_pulse.tiff']); %save as .tiff
            % print(h, '-dtiffn', filen);
            filen = fullfile(dir_fig,'ROI_pulse'); %save as .PNG
            % Save as PNG (2x the resolution, ~8x smaller file size) //EGC
            print(h, '-dpng', filen, '-r300');
            % Save as a figure
            saveas(h, filen, 'fig');
        end
        close(h);
        
        recons_info.ecg_recons.vessel.time_course=vessel_time_course;
        recons_info.ecg_recons.vessel.tAxis = tAxis;
        fprintf(fid, '%s , %6.4f , %6.4f , %6.4f , %6.4f , %6.4f\n', OCT.acqui_info.base_filename, mean(vessel_time_course),...
        median(vessel_time_course),std(vessel_time_course),max(vessel_time_course),min(vessel_time_course));
        OCT.acqui_info=acqui_info;
        OCT.recons_info=recons_info;
        save(fullfile(OCT.output_dir, 'OCT.mat'),'OCT');
    end
    catch exception
        disp(exception.identifier)
        disp(exception.stack(1))
        out.OCTmat{acquisition} = job.OCTmat{acquisition};
    end
end % Acquisitions loop
if ishandle(h);close(h);drawnow;end
fclose(fid);
out.OCTmat = OCTmat;
end

function maximize_figure(h, acqui_info)
%% Graphic options
% Screensize units normalized
set(0,'Units','normalized')
% white background
set(h,'color','w')
% Complement figure colors
set(h,'DefaultAxesColor','w',...
    'DefaultAxesXColor','k',...
    'DefaultAxesYColor','k',...
    'DefaultAxesZColor','k',...
    'DefaultTextColor','k',...
    'DefaultLineColor','k')
% Maximize figure
screenSize = get(0,'Screensize');
screenSize = [screenSize(1)  0.0370 ...
    screenSize(3) ...
    screenSize(4)- 0.0370];
% Change figure name
set(h, 'Name', acqui_info.base_filename)
% Normalized units
set(h, 'Units', 'normalized');
% Maximize figure
set(h, 'OuterPosition', screenSize);
end

% EOF
