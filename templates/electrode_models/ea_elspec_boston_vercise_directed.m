function electrode=ea_elspec_boston_vercise_directed(varargin)

% This function creates the electrode specification for the Vercise directed lead.
% In contrast to other electrode generation functions, it is based on an
% externally generated FEM-compatible model, stored in the
% .\Boston_Vercise_Directed_Components\ subfolder.
% __________________________________________________________________________________
% Copyright (C) 2015 Charite University Medicine Berlin, Movement Disorders Unit
% Andreas Horn

%% import insulations and contacts from subfolder
for k = 1:14
    filename = ['.\Boston_Vercise_Directed_Components\Insulations\' 'ins' num2str(k) '.1'];
    [node,~,face]=readtetgen(filename);
    electrode.insulation(k).vertices = node;
    electrode.insulation(k).faces = face(:,1:3);
    clear face node filename
end

for k = 1:8
    filename = ['.\Boston_Vercise_Directed_Components\Contacts\' 'con' num2str(k) '.1'];
    [node,~,face]=readtetgen(filename);
    electrode.contacts(k).vertices = node;
    electrode.contacts(k).faces = face(:,1:3);
    clear face node filename
end


%% other specifications
electrode.electrode_model = 'Boston Scientific Vercise Directed';
electrode.head_position = [0 0 0.75];
electrode.tail_position = [0 0 6.75];
electrode.x_position = [0.65 0 0.75];
electrode.y_position = [0 0.65 0.75];
electrode.numel = 8;
electrode.contact_color = 0.3;
electrode.lead_color = 0.7;

electrode.coords_mm(1,:)=coords_mm{side}(1,:);
electrode.coords_mm(2,:)=coords_mm{side}(2,:)+[-0.66,0,0];
electrode.coords_mm(3,:)=coords_mm{side}(2,:)+[0.33,0.66,0];
electrode.coords_mm(4,:)=coords_mm{side}(2,:)+[0.33,-0.66,0];
electrode.coords_mm(5,:)=coords_mm{side}(3,:)+[-0.66,0,0];
electrode.coords_mm(6,:)=coords_mm{side}(3,:)+[0.33,0.66,0];
electrode.coords_mm(7,:)=coords_mm{side}(3,:)+[0.33,-0.66,0];
electrode.coords_mm(8,:)=coords_mm{side}(4,:);



save('boston_vercise_directed.mat','electrode');
end