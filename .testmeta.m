%% Load summary statistics for ENIGMA-Epilepsy
sum_stats = load_summary_stats('epilepsy');

% Get case-control subcortical volume and cortical thickness tables
SV = sum_stats.SubVol_case_vs_controls_ltle;
CT = sum_stats.CortThick_case_vs_controls_ltle;

% Extract Cohen's d values
SV_d = SV.d_icv;
CT_d = CT.d_icv;


%% Load and plot functional connectivity data
[fc_ctx, fc_ctx_labels, ~, ~] = load_fc();

% Load and plot structural connectivity data
[sc_ctx, sc_ctx_labels, ~, ~] = load_sc();

% Load and plot functional connectivity data
[~, ~, fc_sctx, fc_sctx_labels] = load_fc();

% Load and plot structural connectivity data
[~, ~, sc_sctx, sc_sctx_labels] = load_sc();


%% Compute weighted degree centrality measures from the connectivity data
fc_ctx_dc           = sum(fc_ctx);
sc_ctx_dc           = sum(sc_ctx);

% Compute weighted degree centrality measures from the connectivity data
fc_sctx_dc          = sum(fc_sctx, 2);
sc_sctx_dc          = sum(sc_sctx, 2);


%% Remove subcortical values corresponding the ventricles
% (as we don't have connectivity values for them!)
SV_d_noVent = SV_d;
SV_d_noVent([find(strcmp(SV.Structure, 'LLatVent')); ...
            find(strcmp(SV.Structure, 'RLatVent'))], :) = [];

% Perform spatial correlations between cortical hubs and Cohen's d
fc_ctx_r = corrcoef(fc_ctx_dc, CT_d);
sc_ctx_r = corrcoef(sc_ctx_dc, CT_d);

% Perform spatial correlations between structural hubs and Cohen's d
fc_sctx_r = corrcoef(fc_sctx_dc, SV_d_noVent);
sc_sctx_r = corrcoef(sc_sctx_dc, SV_d_noVent);

% Store correlation coefficients
rvals = cell2struct({fc_ctx_r(1, 2), fc_sctx_r(1, 2), sc_ctx_r(1, 2), sc_sctx_r(1, 2)}, ...
                    {'functional_cortical_hubs', 'functional_subcortical_hubs', ...
                     'structural_cortical_hubs', 'structural_subcortical_hubs'}, 2);


%% Remove subcortical values corresponding the ventricles
% (as we don't have connectivity values for them!)
SV_d_noVent = SV_d;
SV_d_noVent([find(strcmp(SV.Structure, 'LLatVent')); ...
            find(strcmp(SV.Structure, 'RLatVent'))], :) = [];
        
% Spin permutation testing for two cortical maps
[fc_ctx_p, fc_ctx_d]   = spin_test(fc_ctx_dc, CT_d, 'surface_name', 'fsa5', ...
                                   'parcellation_name', 'aparc', 'n_rot', 1000, ... 
                                   'type', 'pearson');
[sc_ctx_p, sc_ctx_d]   = spin_test(sc_ctx_dc, CT_d, 'surface_name', 'fsa5', ...
                                   'parcellation_name', 'aparc', 'n_rot', 1000, ... 
                                   'type', 'pearson');
                               
% Shuf permutation testing for two subcortical maps 
[fc_sctx_p, fc_sctx_d] = shuf_test(fc_sctx_dc, SV_d_noVent, ...
                                   'n_rot', 1000, 'type', 'pearson');
[sc_sctx_p, sc_sctx_d] = shuf_test(sc_sctx_dc, SV_d_noVent, ...
                                   'n_rot', 1000, 'type', 'pearson');
                               
% Store p-values and null distributions                               
p_and_d =  cell2struct({[fc_ctx_p; fc_ctx_d], [fc_sctx_p; fc_sctx_d], [sc_ctx_p; sc_ctx_d], [sc_sctx_p; sc_sctx_d]}, ...
                       {'functional_cortical_hubs', 'functional_subcortical_hubs', ...
                        'structural_cortical_hubs', 'structural_subcortical_hubs'}, 2);                              

                    
%%
f = figure,
    set(gcf,'color','w');
    set(gcf,'units','normalized','position',[0 0 1 0.3])
    fns = fieldnames(p_and_d);
    
    for k = 1:numel(fieldnames(rvals))
        % Define plot colors
        if k <= 2; col = [0.66 0.13 0.11]; else; col = [0.2 0.33 0.49]; end
        
        % Plot null distributions
        axs = subplot(1, 4, k); hold on
        h = histogram(p_and_d.(fns{k})(2:end), 50, 'Normalization', 'pdf', 'edgecolor', 'w', ...
                      'facecolor', col, 'facealpha', 1, 'linewidth', 0.5); 
        l = line([rvals.(fns{k}) rvals.(fns{k})], get(gca, 'ylim'), 'linestyle', '--', ...
                 'color', 'k', 'linewidth', 1.5);
        xlabel(['Null correlations' newline '(' strrep(fns{k}, '_', ' ') ')'])
        ylabel('Density')
        legend(l,['{\it r}=' num2str(round(rvals.(fns{k}), 2)) newline ...
                  '{\it p}=' num2str(round(p_and_d.(fns{k})(1), 2))])
        legend boxoff
    end

    
    
%% Store degree centrality measures
meas  =  cell2struct({fc_ctx_dc.', fc_sctx_dc, sc_ctx_dc.', sc_sctx_dc}, ...
                     {'Functional_cortical_hubs', 'Functional_subcortical_hubs', ...
                     'Structural_cortical_hubs', 'Structural_subcortical_hubs'}, 2);
fns   = fieldnames(meas);

% Store atrophy measures
meas2 =  cell2struct({CT_d, SV_d_noVent}, {'Cortical_thickness', 'Subcortical_volume'}, 2);
fns2  = fieldnames(meas2);

f = figure,
    set(gcf,'color','w');
    set(gcf,'units','normalized','position',[0 0 1 0.3])
    k2 = [1 2 1 2];
    
    for k = 1:numel(fieldnames(meas))
        j = k2(k);
        
        % Define plot colors
        if k <= 2; col = [0.66 0.13 0.11]; else; col = [0.2 0.33 0.49]; end
        
        % Plot relationships between hubs and atrophy
        axs = subplot(1, 4, k); hold on
        s   = scatter(meas.(fns{k}), meas2.(fns2{j}), 88, col, 'filled'); 
        P1      = polyfit(meas.(fns{k}), meas2.(fns2{j}), 1);                               
        yfit_1  = P1(1) * meas.(fns{k}) + P1(2);
        plot(meas.(fns{k}), yfit_1, 'color',col, 'LineWidth', 3) 
        ylim([-1 0.5])
        xlabel(strrep(fns{k}, '_', ' '))
        ylabel(strrep(fns2{j}, '_', ' '))
        legend(s, ['{\it r}=' num2str(round(rvals.(lower(fns{k})), 2)) newline ...
                  '{\it p}=' num2str(round(p_and_d.(lower(fns{k}))(1), 2))])
        legend boxoff
    end
    

%% Computing cortical epicenter values (from functional connectivity)
fc_ctx_epi              = zeros(size(fc_ctx, 1), 1);
fc_ctx_epi_p            = zeros(size(fc_ctx, 1), 1);
for seed = 1:size(fc_ctx, 1)
    seed_conn           = fc_ctx(:, seed);
    r_tmp               = corrcoef(seed_conn, CT_d);
    fc_ctx_epi(seed)    = r_tmp(1, 2);
    fc_ctx_epi_p(seed)  = spin_test(seed_conn, CT_d, 'surface_name', 'fsa5', 'parcellation_name', ...
                                    'aparc', 'n_rot', 100, 'type', 'pearson');
end

% Computing cortical epicenter values (from structural connectivity)
sc_ctx_epi              = zeros(size(sc_ctx, 1), 1);
sc_ctx_epi_p            = zeros(size(sc_ctx, 1), 1);
for seed = 1:size(sc_ctx, 1)
    seed_conn           = sc_ctx(:, seed);
    r_tmp               = corrcoef(seed_conn, CT_d);
    sc_ctx_epi(seed)    = r_tmp(1, 2);
    sc_ctx_epi_p(seed)  = spin_test(seed_conn, CT_d, 'surface_name', 'fsa5', 'parcellation_name', ...
                                    'aparc', 'n_rot', 1000, 'type', 'pearson');
end

% Project the results on the surface brain
% Selecting only regions with p < 0.1 (functional epicenters)
fc_ctx_epi_p_sig = zeros(length(fc_ctx_epi_p), 1);
fc_ctx_epi_p_sig(find(fc_ctx_epi_p < 0.1)) = fc_ctx_epi(fc_ctx_epi_p<0.1);
f = figure,
    plot_cortical(parcel_to_surface(fc_ctx_epi_p_sig, 'aparc_fsa5'), ...
                  'color_range', [-0.5 0.5], 'cmap', 'GyRd_r')
              
% Selecting only regions with p < 0.1 (structural epicenters)
sc_ctx_epi_p_sig = zeros(length(sc_ctx_epi_p), 1);
sc_ctx_epi_p_sig(find(sc_ctx_epi_p < 0.1)) = sc_ctx_epi(sc_ctx_epi_p<0.1);
f = figure,
    plot_cortical(parcel_to_surface(sc_ctx_epi_p_sig, 'aparc_fsa5'), ...
                  'color_range', [-0.5 0.5], 'cmap', 'GyBu_r')

    
%% Computing subcortical epicenter values (from functional connectivity)
fc_sctx_epi             = zeros(size(fc_sctx, 1), 1);
fc_sctx_epi_p           = zeros(size(fc_sctx, 1), 1);
for seed = 1:size(fc_sctx, 1)
    seed_conn           = fc_sctx(seed, :);
    r_tmp               = corrcoef(seed_conn, CT_d);
    fc_sctx_epi(seed)   = r_tmp(1, 2);
    fc_sctx_epi_p(seed) = spin_test(seed_conn, CT_d, 'surface_name', 'fsa5', 'parcellation_name', ...
                                    'aparc', 'n_rot', 1000, 'type', 'pearson');
end

% Computing subcortical epicenter values (from structural connectivity)
sc_sctx_epi             = zeros(size(sc_sctx, 1), 1);
sc_sctx_epi_p           = zeros(size(sc_sctx, 1), 1);
for seed = 1:size(sc_sctx, 1)
    seed_conn           = sc_sctx(seed, :);
    r_tmp               = corrcoef(seed_conn, CT_d);
    sc_sctx_epi(seed)   = r_tmp(1, 2);
    sc_sctx_epi_p(seed) = spin_test(seed_conn, CT_d, 'surface_name', 'fsa5', 'parcellation_name', ...
                                    'aparc', 'n_rot', 1000, 'type', 'pearson');
end

% Project the results on the surface brain
% Selecting only regions with p < 0.1 (functional epicenters)
fc_sctx_epi_p_sig = zeros(length(fc_sctx_epi_p), 1);
fc_sctx_epi_p_sig(find(fc_sctx_epi_p < 0.1)) = fc_sctx_epi(fc_sctx_epi_p<0.1);
f = figure,
    plot_subcortical(fc_sctx_epi_p_sig, 'ventricles', 'False', ...
                     'color_range', [-0.5 0.5], 'cmap', 'GyRd_r', 'label_text', 'p < 0.1')
                 
% Selecting only regions with p < 0.1 (structural epicenters)
sc_sctx_epi_p_sig = zeros(length(sc_sctx_epi_p), 1);
sc_sctx_epi_p_sig(find(sc_sctx_epi_p < 0.1)) = sc_sctx_epi(sc_sctx_epi_p<0.1);
f = figure,
    plot_subcortical(sc_sctx_epi_p_sig, 'ventricles', 'False', ...
                     'color_range', [-0.5 0.5], 'cmap', 'GyBu_r', 'label_text', 'p < 0.1')
                 
                 