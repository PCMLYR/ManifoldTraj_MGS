function figure_id = draw_cluster(embed_data, clusterIdentifiers, colormap, figure_id)
    if ~exist('figure_id', 'var') figure_id = randi(100) + 200; end
    if ~exist('colormap', 'var') colormap = "rainbow-kov"; end
    fig = figure(figure_id);
    fig.Position = [900 900 800 800];

    N_cluster = max(clusterIdentifiers);
    cmp = [[0,0,0]; slanCM(colormap, N_cluster)];
    clusterIdentifiers = clusterIdentifiers + 1;
    scatter(embed_data(:,1), embed_data(:,2), 10, cmp(clusterIdentifiers,:), "filled");
    xlabel('UMAP-1'); ylabel('UMAP-2');
    xlim([-6 6]); ylim([-7 5.1]);

    hold on;
    h = [patch(NaN, NaN, [0,0,0])]; 
    lgd_name = ["(no cluster)"];
    for c = 1:N_cluster
        h = [h, patch(NaN, NaN, cmp(c+1,:))]; % pseudal object 
        lgd_name = [lgd_name string(['cluster' int2str(c)])];
    end
    ax = axes('Visible', 'off');
    lgd = legend(ax, h, lgd_name);
    lgd.Position = [0.1 0 0.8 0.1]; 
    lgd.Orientation = 'horizontal';
    lgd.FontName = 'Times New Roman';
    lgd.FontWeight = "bold";
    lgd.FontSize = 12;
    lgd.Interpreter = "none";
    lgd.NumColumns = fix((N_cluster+1)/2)-1;
    hold off;
end