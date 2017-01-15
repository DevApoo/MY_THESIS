%% (Internal) Concatenate two payloads.
% This function is used by the ECGtask related with QRS detection.
%   
% Example
% 
%   payload = ConcatenateQRSdetectionPayloads(obj, plA, plB)
% 
% Arguments:
%      +obj: ECGtask_QRS_Detection instance
% 
%     +plA, plB: payloads generated by ECGtask_QRS_Detection.Process. 
% 
% Output:
%     + payload: payloads generated by ECGtask_QRS_Detection.Process result
%        of concatenating plA and plB.
% 
% See also ECGtask_QRS_Detection
% 
% Author: Mariano Llamedo Soria llamedom@electron.frba.utn.edu.ar
% Version: 0.1 beta
% Last update: 14/5/2014
% Birthdate  : 23/4/2013
% Copyright 2008-2015
function payload = ConcatenateQRSdetectionPayloads(obj, plA, plB)

    if( isempty(plA) )

        payload = plB;

    else

        fields = rowvec(unique( [rowvec(fieldnames(plA)) rowvec(fieldnames(plB))] ));

        diff_fields = setdiff(fields, {'series_quality' 'series_performance' });

        for fn = diff_fields

            if( isfield(plA, fn{1}) && isfield(plB, fn{1}) )
                payload.(fn{1}).time = [ colvec(plA.(fn{1}).time); colvec(plB.(fn{1}).time) ];

            elseif( ~isfield(plA, fn{1}) && isfield(plB, fn{1}) )
                payload.(fn{1}).time = colvec(plB.(fn{1}).time);
            end

        end

        aux_idx = find(strcmpi(fields, 'series_quality' ));

        if( isempty(aux_idx) )
            if( obj.CalculateArtificialDetections )
                disp_string_framed(2, '"series_quality" field not found in tmp files. Wrong configuration ? Try cleanning tmp files and run again.' )
            end
        else                    
            if( isfield(plA, 'series_quality') && isfield(plB, 'series_quality') )
                if( size(plA.series_quality.ratios,1) == size(plB.series_quality.ratios,1) )
                    payload.series_quality.ratios = [plA.series_quality.ratios plB.series_quality.ratios];
                    payload.series_quality.estimated_labs = cellfun(@(a,b)( [colvec(a);colvec(b)] ) , plA.series_quality.estimated_labs, plB.series_quality.estimated_labs, 'UniformOutput', false);
                    payload.series_quality.AnnNames = plA.series_quality.AnnNames;
                else
                    payload.series_quality.ratios = plA.series_quality.ratios;
                    payload.series_quality.estimated_labs = plA.series_quality.estimated_labs;
                    payload.series_quality.AnnNames = plA.series_quality.AnnNames;
                end
            end

            aux_idx = find(strcmpi(fields, 'series_performance' ));

            if( ~isempty(aux_idx) )

                [~, aux_idxA, aux_idxB] = intersect(plA.series_quality.AnnNames(:,1), plB.series_quality.AnnNames(:,1));

                if( obj.CalculatePerformance && size(plA.series_quality.AnnNames,1) ~= length(aux_idxA) ) 
                    aux_valDiff = setdiff(plA.series_quality.AnnNames(:,1), plB.series_quality.AnnNames(:,1));
                    disp_string_framed(2, 'WARNING!! Performance not completely calculated ' );
                    fprintf(2, disp_option_enumeration('Performance not calculated for leads:', aux_valDiff ) );
                end

                if( isfield(plA, 'series_performance') && isfield(plB, 'series_performance') )
                    payload.series_performance.conf_mat = plA.series_performance.conf_mat(:,:,aux_idxA) + plB.series_performance.conf_mat(:,:,aux_idxB);
                    payload.series_performance.conf_mat_details = cellfun(@(a,b)([colvec(a);colvec(b)]), plA.series_performance.conf_mat_details(aux_idxA,:), plB.series_performance.conf_mat_details(aux_idxB,:), 'UniformOutput', false );
                    payload.series_performance.error = cat(3, plA.series_performance.error(aux_idxA,:,:), plB.series_performance.error(aux_idxA,:));
                else
                    if( obj.CalculatePerformance )
                        disp_string_framed(2, 'WARNING!! Performance not calculated ' );
                        disp_string_framed(2, '"series_performance" field not found in both tmp files. Different configuration options ? Try cleanning tmp files and run again.' )
                    end
                end

            end

        end

    end

