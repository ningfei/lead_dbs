function ea_lcm(options)

% the order may be crucial since VAT-seeds are resliced in fMRI
if options.lcm.struc.do
    % main wrapper for lead connectome mapper runs
    if strcmp(options.lcm.seeddef,'vats')
        originalseeds=options.lcm.seeds;
        options.lcm.seeds=ea_resolvevatseeds(options,'dMRI');
        if isempty(options.lcm.odir)
            options.lcm.odir=[fileparts(options.lcm.seeds{1}),filesep,options.lcm.struc.connectome,filesep];
            if ~exist(options.lcm.odir,'dir')
                mkdir(options.lcm.odir);
            end
        end
    elseif strcmp(options.lcm.seeddef,'parcellation')
   %     keyboard
    end

    ea_lcm_struc(options);
end

if options.lcm.func.do
    if strcmp(options.lcm.seeddef,'vats')
        if exist('originalseeds','var')
            options.lcm.seeds=originalseeds;
        end
        options.lcm.seeds=ea_resolvevatseeds(options,'fMRI');
        if isempty(options.lcm.odir) && ~strcmp(options.lcm.seeddef,'vats')
            options.lcm.odir=[fileparts(options.lcm.seeds{1}),filesep,options.lcm.func.connectome,filesep];
            if ~exist(options.lcm.odir,'dir')
                mkdir(options.lcm.odir);
            end
        end
    elseif strcmp(options.lcm.seeddef,'parcellation')
        options.lcm.seeds=ea_resolveparcseeds(options,'fMRI');
    end

    % check if patient specific connectome used:
    patientspecific=0;
    try
        if strcmp(options.lcm.func.connectome(1:16),'Patient-specific')
            patientspecific=1;
        end
    end

    if ~patientspecific
        ea_lcm_func(options);
    else % need to supply each patient on its own since each uses different connectome.
        allseeds=options.lcm.seeds;
        allvatdirs=options.uivatdirs;
        for seed=1:length(allseeds)
            options.lcm.seeds=allseeds(seed);
            options.uivatdirs=allvatdirs(seed);
            ea_lcm_func(options);
        end
        options.lcm.seeds=allseeds;
        options.uivatdirs=allvatdirs;
    end
end

% convert VTA seeds also if neither func or struc conn is chosen.
if (~options.lcm.func.do) && (~options.lcm.struc.do)
    if strcmp(options.lcm.seeddef,'vats')
        ea_resolvevatseeds(options,'dMRI');
        ea_resolvevatseeds(options,'fMRI');
    end
end


function seeds=ea_resolveparcseeds(options,modality)
switch modality
    case 'fMRI'
        tmp=ea_getleadtempdir;
        uuid=ea_generate_uuid;
        [~,~,ext]=ea_niifileparts(options.lcm.seeds{1});
        copyfile(options.lcm.seeds{1},fullfile(tmp,[uuid,ext]));
        if strcmp(ext,'.nii.gz')
            gunzip(fullfile(tmp,[uuid,ext]));
            delete(fullfile(tmp,[uuid,ext]));
        end
        [pth,fn,ext]=ea_niifileparts(ea_niigz([ea_getearoot,'templates',filesep,'spacedefinitions',filesep,'222']));
        copyfile(ea_niigz([ea_getearoot,'templates',filesep,'spacedefinitions',filesep,'222']),[tmp,'222',ext]);
        if strcmp(ext,'.nii.gz')
            gunzip([tmp,'222',ext]);
            delete([tmp,'222',ext]);
        end
        ea_conformspaceto([tmp,'222','.nii'],ea_niigz(fullfile(tmp,uuid)),...
            0,[],fullfile(tmp,[uuid,'.nii']),0);
        seeds={fullfile(tmp,[uuid,'.nii'])};
    case 'dMRI'
       seeds=options.lcm.seeds; % leave as is.
end
% % load in txt
% fid=fopen(fullfile(fileparts(options.lcm.seeds{1}),[ea_stripex(ea_stripex(options.lcm.seeds{1})),'.txt']),'r');
% A=textscan(fid,'%f %s\n');
% idx=A{1};


function seeds=ea_resolvevatseeds(options,modality)
disp('Preparing VATs as seedfiles...');

suffices={'binary','efield','efield_gauss'};

[~,dowhich]=ismember(options.prefs.lcm.vatseed,suffices);
for suffix=dowhich

    switch suffices{suffix}
        case 'binary'
            addstr='';
            dinterp=0;
        case 'efield_gauss'
            addstr='_efield_gauss';
            dinterp=1;
        case 'efield'
            addstr='_efield';
            dinterp=1;
    end
    if strcmp(options.prefs.lcm.vatseed,suffices{suffix})
        keepthisone=1;
    else
        keepthisone=0;
    end

    % prepare for dMRI
    switch modality
        case 'dMRI'
            seeds=cell(0);
            for pt=1:length(options.uivatdirs)
                vatdir=[options.uivatdirs{pt},filesep,'stimulations',filesep,options.lcm.seeds,filesep];

            %if ~exist([vatdir,'vat_seed_compound_dMRI',addstr,'.nii'],'file');
                cnt=1;
                for side=1:2
                    switch side
                        case 1
                            sidec='right';
                        case 2
                            sidec='left';
                    end

                    if exist([vatdir,'vat',addstr,'_',sidec,'.nii'],'file')
                        copyfile([vatdir,'vat',addstr,'_',sidec,'.nii'],[vatdir,'tmp_',sidec,'.nii']);
                        ea_conformspaceto([ea_space,'bb.nii'],[vatdir,'tmp_',sidec,'.nii'],dinterp);
                        nii(cnt)=ea_load_nii([vatdir,'tmp_',sidec,'.nii']);
                        cnt=cnt+1;
                    end
                end

                Cnii=nii(1);
                for n=2:length(nii)
                    Cnii.img=Cnii.img+nii(n).img;
                end
                Cnii.fname=[vatdir,'vat_seed_compound_dMRI',addstr,'.nii'];
                ea_write_nii(Cnii);
                ea_crop_nii(Cnii.fname);
                delete([vatdir,'tmp_*']);

                ea_split_nii_lr(Cnii.fname);
                disp('Done.');
                %end
                if keepthisone
                    seeds{end+1}=[vatdir,'vat_seed_compound_dMRI',addstr,'.nii'];
                end
            end
        case 'fMRI'
            % prepare for fMRI
            %if ~exist([vatdir,'vat_seed_compound_fMRI',addstr,'.nii'],'file');
            seeds=cell(0);
            nativeprefix='';
            for pt=1:length(options.uivatdirs)
                vatdir=[options.uivatdirs{pt},filesep,'stimulations',filesep,options.lcm.seeds,filesep];

                cnt=1;
                for side=1:2
                    switch side
                        case 1
                            sidec='right';
                        case 2
                            sidec='left';
                    end

                    if exist([vatdir,'vat',addstr,'_',sidec,'.nii'],'file')
                        copyfile([vatdir,'vat',addstr,'_',sidec,'.nii'],[vatdir,'tmp_',sidec,'.nii']);
                        tnii=ea_load_nii([vatdir,'tmp_',sidec,'.nii']);
                        tnii.dt=[16,0];
                        ea_write_nii(tnii);
                        cname=options.lcm.func.connectome;

                        if ismember('>',cname)
                            delim=strfind(cname,'>');
                            subset=cname(delim+1:end);
                            cname=cname(1:delim-1);
                        end
                        if ~strcmp(cname,'No functional connectome found.')
                            if ~exist([ea_getconnectomebase('fMRI'),cname,filesep,'dataset_info.mat'],'file') % patient specific rs-fMRI
                                ea_warp_vat2rest(cname,vatdir,sidec,options);
                                nativeprefix=['_',cname(25:end)];
                            else
                                d=load([ea_getconnectomebase('fMRI'),cname,filesep,'dataset_info.mat']);
                                d.dataset.vol.space.fname=[vatdir,'tmp_space.nii'];
                                d.dataset.vol.space.dt=[16,0];
                                ea_write_nii(d.dataset.vol.space);
                                ea_conformspaceto(d.dataset.vol.space.fname,[vatdir,'tmp_',sidec,'.nii'],1);
                            end
                            nii(cnt)=ea_load_nii([vatdir,'tmp_',sidec,'.nii']);
                            nii(cnt).img(isnan(nii(cnt).img))=0;
                            if ~any(nii(cnt).img(:))
                                msgbox(['Created empty VTA for ',options.patientname,'(',options.uivatdirs{pt},'), ',sidec,' hemisphere.']);
                            end
                        end
                        cnt=cnt+1;

                    end

                end
                Cnii=nii(1);
                for n=2:length(nii)
                    Cnii.img=Cnii.img+nii(n).img;
                end
                Cnii.fname=[vatdir,'vat_seed_compound_fMRI',addstr,nativeprefix,'.nii'];
                ea_write_nii(Cnii);
                delete([vatdir,'tmp_*']);

                ea_split_nii_lr(Cnii.fname);
                disp('Done.');
                %end
                if keepthisone
                    seeds{end+1}=[vatdir,'vat_seed_compound_fMRI',addstr,nativeprefix,'.nii'];
                end
            end
    end
end


function ea_warp_vat2rest(cname,vatdir,sidec,options)

if strncmp(cname, 'Patient-specific fMRI - ', 24)
    restfname = cname(25:end);
else
    restfname = cname;
end
options.prefs.rest=[restfname,'.nii']; % make sure the proper rest_* is used

directory=[fileparts(fileparts(fileparts(vatdir))),filesep];
options=ea_getptopts(directory,options);

% warp VTA to native subject space (anchor modality):
ea_apply_normalization_tofile(options,{[vatdir,'tmp_',sidec,'.nii']},{[vatdir,'tmp_',sidec,'.nii']},directory,1,1);

% get peak coordinate for if empty image results when downsampling to
% resting state file
anat_vat = ea_load_nii([vatdir,'tmp_',sidec,'.nii']);
[~,ix] = max(anat_vat.img(:));
[xx,yy,zz] = ind2sub(size(anat_vat.img),ix);
vox_anat = [xx;yy;zz;1];

% prepare coregistration from anchor modality to rest file
refname = ['r',restfname];
[~,anatfname] = fileparts(options.prefs.prenii_unnormalized);

% The real reference image is 'meanrrest_*.nii' rather than 'rrest_*.nii'
reference = ['mean', restfname,'.nii'];

% Check coregistration method
try
    load([directory,'ea_coregmrmethod_applied.mat'],'coregmr_method_applied');
    % Disable Hybrid coregistration
    coregmethod = strrep(coregmr_method_applied{end}, 'Hybrid SPM & ', '');
catch
    coregmethod = 'SPM'; % fallback to SPM coregistration
end

options.coregmr.method = coregmethod;

% Check if the transformation already exists
xfm = [anatfname, '2', refname, '_', lower(coregmethod), '\d*\.(mat|h5)$'];
transform = ea_regexpdir(directory, xfm, 0);

if numel(transform) == 0
    warning('Transformation not found! Running coregistration now!');
    transform = ea_coreg2images(options,[directory,options.prefs.prenii_unnormalized],...
        [directory,reference],...
        [directory,refname,'_',options.prefs.prenii_unnormalized],...
        [],1,[],1);
    transform = transform{1}; % Forward transformation
else
    if numel(transform) > 1
        warning(['Multiple transformations of the same type found! ' ...
                 'Will use the last one:\n%s'], transform{end});
    end
    transform = transform{end};
end

% Apply transformation
ea_apply_coregistration([directory,reference], ...
    [vatdir,'tmp_',sidec,'.nii'], ...
    [vatdir,'tmp_',sidec,'.nii'], ...
    transform, 'linear');

rest_vat=ea_load_nii([vatdir,'tmp_',sidec,'.nii']);
if ~any(rest_vat.img(:)) % image empty, at least set original peak to 1.
    warning('Image empty (potentially due to poor resolution and interpolation), trying to set peak manually');
    [~, vox_rest] = ea_map_coords(vox_anat, ...
        [directory, options.prefs.prenii_unnormalized], ...
        transform, reference, upper(coregmethod));
    vox_rest=round(vox_rest);
    try
        rest_vat.img(vox_rest(1),vox_rest(2),vox_rest(3))=1;
        ea_write_nii(rest_vat);
    catch
        msgbox(['Attempted to manually set peak voxel to ''',rest_vat.fname,''', but it seems to reside out of bounds.']);
    end
end
