function atlases=ea_genatlastable(atlases,root,options)
% This function reads in atlases in the Lead-dbs/atlases directory and
% generates a table of all available atlas files.
% Atlastypes:   1 ? LH
%               2 ? RH
%               3 ? both hemispheres (2 files present both in lhs and rhs
%               folder
%               4 ? mixed (one file with one cluster on each hemisphere)
%               5 ? midline (one file with one cluster in total)
%
%
% __________________________________________________________________________________
% Copyright (C) 2014 Charite University Medicine Berlin, Movement Disorders Unit
% Andreas Horn

 

if isempty(atlases) % create from scratch - if not empty, rebuild flag has been set.
       disp('Generating Atlas table (first run with new atlas only). This may take a while...');
 
    
    lhcell=cell(0); rhcell=cell(0); mixedcell=cell(0); midlinecell=cell(0);
    delete([root,'atlases',filesep,options.atlasset,filesep,'lh',filesep,'*_temp.ni*']);
    lhatlases=dir([root,'atlases',filesep,options.atlasset,filesep,'lh',filesep,'*.ni*']);
    for i=1:length(lhatlases);
        lhcell{i}=lhatlases(i).name;
    end
    delete([root,'atlases',filesep,options.atlasset,filesep,'rh',filesep,'*_temp.ni*']);
    rhatlases=dir([root,'atlases',filesep,options.atlasset,filesep,'rh',filesep,'*.ni*']);
    for i=1:length(rhatlases);
        rhcell{i}=rhatlases(i).name;
    end
    delete([root,'atlases',filesep,options.atlasset,filesep,'mixed',filesep,'*_temp.ni*']);
    mixedatlases=dir([root,'atlases',filesep,options.atlasset,filesep,'mixed',filesep,'*.ni*']);
    for i=1:length(mixedatlases);
        mixedcell{i}=mixedatlases(i).name;
    end
    delete([root,'atlases',filesep,options.atlasset,filesep,'midline',filesep,'*_temp.ni*']);
    
    midlineatlases=dir([root,'atlases',filesep,options.atlasset,filesep,'midline',filesep,'*.ni*']);
    for i=1:length(midlineatlases);
        midlinecell{i}=midlineatlases(i).name;
    end
    
    % concatenate lh and rh
    todeletelh=[];
    todeleterh=[];
    for i=1:length(lhcell)
        
        [ism, loc]=ismember(lhcell{i},rhcell);
        if ism
            
            todeletelh=[todeletelh,i];
            todeleterh=[todeleterh,loc];
        end
        
    end
    
    bothcell=lhcell(todeletelh);
    lhcell(todeletelh)=[];
    rhcell(todeleterh)=[];
    
    allcell=[rhcell,lhcell,bothcell,mixedcell,midlinecell];
    typecell=[repmat(1,1,length(rhcell)),repmat(2,1,length(lhcell)),repmat(3,1,length(bothcell)),repmat(4,1,length(mixedcell)),repmat(5,1,length(midlinecell))];
    atlases.names=allcell;
    atlases.types=typecell;
    atlases.rebuild=0;
    atlases.threshold.type='relative_intensity';
    atlases.threshold.value=0.5;
    
end




if checkrebuild(atlases)


%% build iXYZ tables:

maxcolor=64; % change to 45 to avoid red / 64 to use all colors


nm=[0:1]; % native and mni
try
    nmind=[options.atl.pt,options.atl.can]; % which shall be performed?
catch
    nmind=[0 1];
end
nm=nm(logical(nmind)); % select which shall be performed.



for nativemni=nm % switch between native and mni space atlases.
    
    switch nativemni
        case 0
            root=[options.root,options.patientname,filesep];
        case 1
            root=options.earoot;
    end
    
    atlascnt=1;
    
    
    % iterate through atlases, visualize them and write out stats.
    ea_dispercent(0,'Building atlas table');
    for atlas=1:length(atlases.names)
        ea_dispercent(atlas/length(atlases.names));
        switch atlases.types(atlas)
            case 1 % right hemispheric atlas.
                nii=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'rh',filesep,atlases.names{atlas}],options);
            case 2 % left hemispheric atlas.
                nii=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'lh',filesep,atlases.names{atlas}],options);
            case 3 % both-sides atlas composed of 2 files.
                lnii=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'lh',filesep,atlases.names{atlas}],options);
                rnii=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'rh',filesep,atlases.names{atlas}],options);
            case 4 % mixed atlas (one file with both sides information).
                nii=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'mixed',filesep,atlases.names{atlas}],options);
            case 5 % midline atlas (one file with both sides information.
                nii=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'midline',filesep,atlases.names{atlas}],options);
        end
        
        
        
        for side=detsides(atlases.types(atlas));
            
            if atlases.types(atlas)==3 % both-sides atlas composed of 2 files.
                if side==1
                    nii=rnii;
                elseif side==2
                    nii=lnii;
                end
            end
            
            
            
            
            colornames='bgcmywkbgcmywkbgcmywkbgcmywkbgcmywkbgcmywkbgcmywkbgcmywkbgcmywk'; % red is reserved for the VAT.
            
            colorc=colornames(1);
            colorc=rgb(colorc);
            
            [xx,yy,zz]=ind2sub(size(nii.img),find(nii.img>0)); % find 3D-points that have correct value.
            vv=nii.img(nii.img(:)>0);
            
            if ~isempty(xx)
                
                XYZ.vx=[xx,yy,zz]; % concatenate points to one matrix.
                XYZ.val=vv;
                XYZ.mm=map_coords_proxy(XYZ.vx,nii); % map to mm-space
                XYZ.dims=nii.hdr.dime.pixdim;
                
                
                
                
            end
            
            %surface(xx(1:10)',yy(1:10)',zz(1:10)',ones(10,1)');
%             hold on
            
            
            
            
            
            
            
            
            if atlases.types(atlas)==4 && side==2 % restore from backup
                nii=bnii;
                XYZ.mm=bXYZ.mm;
                XYZ.val=bXYZ.val;
                XYZ.vx=bXYZ.vx;
            end
            
            bb=[0,0,0;size(nii.img)];
            
            bb=map_coords_proxy(bb,nii);
            gv=cell(3,1);
            for dim=1:3
                gv{dim}=linspace(bb(1,dim),bb(2,dim),size(nii.img,dim));
            end
            
            
            
            if atlases.types(atlas)==4 % mixed atlas, divide
                if side==1
                    bnii=nii;
                    bXYZ=XYZ;
                    
                    nii.img=nii.img(gv{1}>0,:,:);
                    gv{1}=gv{1}(gv{1}>0);
                    
                    XYZ.vx=XYZ.vx(XYZ.mm(:,1)>0,:,:);
                    XYZ.val=XYZ.val(XYZ.mm(:,1)>0,:,:);
                    XYZ.mm=XYZ.mm(XYZ.mm(:,1)>0,:,:);

                    
                    nii.dim=[length(gv{1}),length(gv{2}),length(gv{3})];
                elseif side==2
                    nii.img=nii.img(gv{1}<0,:,:);
                    gv{1}=gv{1}(gv{1}<0);
                    XYZ.vx=XYZ.vx(XYZ.mm(:,1)<0,:,:);
                    XYZ.val=XYZ.val(XYZ.mm(:,1)<0,:,:);
                    XYZ.mm=XYZ.mm(XYZ.mm(:,1)<0,:,:);

                    nii.dim=[length(gv{1}),length(gv{2}),length(gv{3})];
                end
            end
            
            
            [X,Y,Z]=meshgrid(gv{1},gv{2},gv{3});
            if options.prefs.hullsmooth
                nii.img = smooth3(nii.img,'gaussian',options.prefs.hullsmooth);
            end
            
            thresh=ea_detthresh(atlases,atlas,nii.img);
            fv=isosurface(X,Y,Z,permute(nii.img,[2,1,3]),thresh);
            
            if ischar(options.prefs.hullsimplify)
                
                % get to 700 faces
                simplify=700/length(fv.faces);
                fv=reducepatch(fv,simplify);
                
            else
                if options.prefs.hullsimplify<1 && options.prefs.hullsimplify>0
                    
                    fv=reducepatch(fv,options.prefs.hullsimplify);
                elseif options.prefs.hullsimplify>1
                    simplify=options.prefs.hullsimplify/length(fv.faces);
                    fv=reducepatch(fv,simplify);
                end
            end
            
            % temporally plot atlas to get vertex normals..
                tmp=figure('visible','off');
                tp=patch(fv);
                
                normals{atlas,side}=get(tp,'VertexNormals');
                delete(tmp);
            
            
            % set cdata
            
            try % check if explicit color info for this atlas is available.
                cdat=abs(repmat(atlases.colors(atlas),length(fv.vertices),1) ... % C-Data for surface
                    +randn(length(fv.vertices),1)*2)';
            catch
                cdat=abs(repmat(atlas*(maxcolor/length(atlases.names)),length(fv.vertices),1)... % C-Data for surface
                    +randn(length(fv.vertices),1)*2)';
                atlases.colors(atlas)=atlas*(maxcolor/length(atlases.names));
            end
            
            ifv{atlas,side}=fv; % later stored
            icdat{atlas,side}=cdat; % later stored
            iXYZ{atlas,side}=XYZ; % later stored
            ipixdim{atlas,side}=nii.hdr.dime.pixdim(1:3); % later stored
            
            icolorc{atlas,side}=colorc; % later stored
            
            pixdim=ipixdim{atlas,side};
            
            
            
            
            atlascnt=atlascnt+1;
            
            
        end
    end
    ea_dispercent(1,'end');
    
    
    
    
    % save table information that has been generated from nii files (on first run with this atlas set).
    
    atlases.fv=ifv;
    atlases.cdat=icdat;
    atlases.XYZ=iXYZ;
    atlases.pixdim=ipixdim;
    atlases.colorc=icolorc;
    atlases.normals=normals;
    
    
    atlases.rebuild=0; % always reset rebuild flag.
    save([root,'atlases',filesep,options.atlasset,filesep,'atlas_index.mat'],'atlases','-v7.3');
    
    
end

end



function nii=load_nii_proxy(fname,options)

if strcmp(fname(end-2:end),'.gz')
    wasgzip=1;
    gunzip(fname);
    fname=fname(1:end-3);
else
    wasgzip=0;
end
try
    nii=spm_vol(fname);
    
    nii.img=spm_read_vols(nii);
catch
    
end


nii.hdr.dime.pixdim=nii.mat(logical(eye(4)));
if ~all(abs(nii.hdr.dime.pixdim(1:3))<=1)
    reslice_nii(fname,fname,[0.5,0.5,0.5],3);
    
    nii=spm_vol(fname);
    nii.img=spm_read_vols(nii);
    nii.hdr.dime.pixdim=nii.mat(logical(eye(4)));
    
end
if wasgzip
    delete(fname); % since gunzip makes a copy of the zipped file.
end


function sides=detsides(opt)

switch opt
    case 1 % left hemispheric atlas
        sides=1;
    case 2 % right hemispheric atlas
        sides=2;
    case 3
        sides=1:2;
    case 4
        sides=1:2;
    case 5
        sides=1; % midline
        
end



function coords=map_coords_proxy(XYZ,V)

XYZ=[XYZ';ones(1,size(XYZ,1))];

coords=V.mat*XYZ;
coords=coords(1:3,:)';





function C=rgb(C) % returns rgb values for the colors.

C = rem(floor((strfind('kbgcrmyw', C) - 1) * [0.25 0.5 1]), 2);



function reb=checkrebuild(atlases)
reb=1;
if isfield(atlases,'fv')
    reb=0;
    if ~isfield(atlases.XYZ{1,1},'mm')
        reb=1;
    end
end
try
    if atlases.rebuild
        reb=1;
    end
end
