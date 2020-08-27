% SCRIPT TO COMPUTE RISK FACTORS FOR CRYPTOJACKING
% author: Giorgio Di Tizio
clear all
close all


initial_miners = readtable('../Data/list_miners_found_minesweeper.txt','Delimiter', ',','ReadVariableNames',false);
initial_miners = unique(initial_miners);
%% TRANCO RANKING
ranking_miners_table = readtable('../Data/ranking_tranco_case.csv','Delimiter', ',','ReadVariableNames',false);
ranking_control_table = readtable('../Data/list_potential_control.csv','Delimiter', ',','ReadVariableNames',false);

ranking_miners = ranking_miners_table.('Var2');
ranking_control = ranking_control_table.('Var2');
figure
edges = [0 500000 1000000 1500000 2000000 2500000 3000000 3500000 4000000 4500000 5000000 5500000 6000000 6500000 7000000 7500000];
h_miner = histogram(ranking_miners,edges,'FaceColor','#0000FF');
hold on
h_control = histogram(ranking_control,edges,'FaceAlpha',0.3,'FaceColor','#EDB120');
legend('Case group','Control group')
xlabel("Tranco Ranking [in Million]")
ylabel("Frequency")

fprintf("Number of websites in case with associated Tranco Ranking: %d\n",length(ranking_miners))
fprintf("Max case ranking: %d\n",max(ranking_miners))
fprintf("Min case ranking: %d\n",min(ranking_miners))
fprintf("###########################\n")
fprintf("Max control ranking: %d\n",max(ranking_control))
fprintf("Min control ranking: %d\n",min(ranking_control))
print -depsc histogram_ranking.eps

%% READ DATA WHATWEB

%read miners csv file
table_miners = readtable('../Data/parsed_whatweb_case_tranco.csv','Delimiter',',','ReadVariableNames',true);
%read control group csv file
table_control = readtable('../Data/parsed_whatweb_control.csv','Delimiter',',','ReadVariableNames',true);

[n_rows_miners,n_columns_miners] = size(table_miners);
[n_rows_control,n_columns_control] = size(table_control);

%print info size dataset
%check if there are empty entry and count number of websites
n_websites_control = length(table_control.('website')) - sum(string(table_control.('website'))=="");
n_websites_miners = length(table_miners.('website')) - sum(string(table_miners.('website'))=="");
fprintf("Number of elements in control group: %d\n",n_websites_control);
fprintf("Number of elements in miners group: %d\n",n_websites_miners);

%delete empty rows
table_control(string(table_control.('website'))=="",:)=[];

%% HISTOGRAMS SERVER COMPOSITION

servers_miners = categorical(table_miners.('server'));
servers_control = categorical(table_control.('server'));
%filter to consider only server type with a number of occurence of at least
%2% of the size of the dataset
percentage=2;
threshold_server_miners = round((n_rows_miners*percentage)/100);
threshold_server_control = round((n_rows_control*percentage)/100);

[N,servers_min] = histcounts(servers_miners);
%list of web server with at least 2% of the server in the dataset of miners
s_miners = servers_min(N>=threshold_server_miners);
%create a histogram only for these web servers
hist_miners_server = [];
%create a list of 0-1 to determine the others category
others_s_miners = zeros(length(servers_miners),1);
for i=1:length(s_miners)
    match = servers_miners==s_miners(i);
    others_s_miners = others_s_miners + match;
    n_occurences = sum(match);
    for j=1:n_occurences
        hist_miners_server = [hist_miners_server s_miners(i)];
    end
end
for j=1:sum(others_s_miners==0)
    hist_miners_server = [hist_miners_server 'others'];
end

[N,servers_contr] = histcounts(servers_control);
%list of web server with at least 2% of the server in the dataset of
%control
s_contr = servers_contr(N>=threshold_server_control);
%create a histogram only for these web servers
hist_control_server = [];
%create a list of 0-1 to determine the others category
others_s_control = zeros(length(servers_control),1);
for i=1:length(s_contr)
    match = servers_control==s_contr(i);
    others_s_control = others_s_control + match;
    n_occurences = sum(match);
    for j=1:n_occurences
        hist_control_server = [hist_control_server s_contr(i)];
    end
end
for j=1:sum(others_s_control==0)
    hist_control_server = [hist_control_server 'others'];
end
%plot the histogram of all the server types
figure;
h_miners = histogram(categorical(hist_miners_server));
h_miners.DisplayOrder = 'descend';
xtickangle(90);
%title('Histogram server type case');
xlabel('Type of Server')
ylabel('Number of occurences')
saveas(gcf,'hist_case_server','epsc')

figure
h_control = histogram(categorical(hist_control_server));
h_control.DisplayOrder = 'descend';
xtickangle(90);
%title('Histogram server type control');
xlabel('Type of Server')
ylabel('Number of occrences')
saveas(gcf,'hist_control_server','epsc')

%for web server percentage is ok to use the total number of elements in the
%group because you need a web server. For those that are empty it is just
%they did not detect them.
[occurences_control, type_control] = histcounts(categorical(hist_control_server))
percentage_control_server = (occurences_control*100.0)/n_websites_control
tab_count_server_control = table(type_control',percentage_control_server','VariableNames',{'Server','Percentage'});

[occurences_miners, type_miners] = histcounts(categorical(hist_miners_server))
percentage_miners_server = (occurences_miners*100.0)/n_websites_miners
tab_count_server_miners = table(type_miners',percentage_miners_server','VariableNames',{'Server','Percentage'});

%bar chart grouped server type
figure;
market_share_server = [38.7;14.0;6.5;8.1;32.1;0.6];
server_name = categorical(["apache","cloudflare","litespeed","microsoft-IIS","nginx","others"]);
control_server = [];
case_server = [];
for i=1:length(server_name)
   control_server = [control_server; tab_count_server_control.('Percentage')(tab_count_server_control.('Server')==server_name(i))];
   case_server = [case_server; tab_count_server_miners.('Percentage')(tab_count_server_miners.('Server')==server_name(i))];
end
table_percentage_server = table(server_name',market_share_server,control_server,case_server);
%order by market share
table_percentage_server = sortrows(table_percentage_server,2,'descend');
bar(reordercats(table_percentage_server.('Var1'),cellstr(table_percentage_server.('Var1'))),[table_percentage_server.('market_share_server') table_percentage_server.('control_server') table_percentage_server.('case_server')])
xlabel('Server Type')
ylabel('Percentage in the group (%)')
legend('market share','control group', 'case group')
saveas(gcf,'hist_market_server','epsc')

%% CMS ANALYSIS

%show histogram type of CMS used by control and miners 

cms_miners = categorical(table_miners.('cms'));
cms_control = categorical(table_control.('cms'));

%for the histogram only consider the CMS with the highest Market share (https://w3techs.com/technologies/history_overview/content_management)
array_cms = ["WordPress","Joomla","Shopify","Drupal","Squarespace","Wix","Bitrix","Blogger","Magento","PrestaShop","OpenCart","TYPO3","Weebly"];

index_miners = ones(length(cms_miners),1);
index_control = ones(length(cms_control),1);

hist_miners_cms = [];
hist_control_cms = [];
%we want to get the index of the elements that are not one of the CMS in
%the array_cms and rename them as 'others'
for i=1:length(array_cms)
    index_miners = index_miners - (cms_miners==array_cms(i));
    index_control = index_control - (cms_control==array_cms(i));
    for j=1:sum(cms_miners==array_cms(i))
        hist_miners_cms = [hist_miners_cms array_cms(i)];
    end
    for t=1:sum(cms_control==array_cms(i))
        hist_control_cms = [hist_control_cms array_cms(i)];
    end
end
%we also eliminate the one that are undefined, i.e. they have not a CMS
index_miners = index_miners - isundefined(cms_miners);
index_control = index_control - isundefined(cms_control);

for i=1:sum(index_miners)
    hist_miners_cms = [hist_miners_cms 'others'];
end

for j=1:sum(index_control)
    hist_control_cms = [hist_control_cms 'others'];
end

hist_miners_cms = categorical(hist_miners_cms);
hist_control_cms = categorical(hist_control_cms);

%plot the histogram of all the cms types
figure;
h_cms_miners = histogram(hist_miners_cms);%(cms_miners);
h_cms_miners.DisplayOrder = 'descend';
xtickangle(90);
xlabel('Type of CMS')
ylabel('Number of occurences')
saveas(gcf,'hist_case_CMS','epsc')

figure;
h_cms_control = histogram(hist_control_cms);%(cms_control);
h_cms_control.DisplayOrder = 'descend';
xtickangle(90);
xlabel('Type of CMS')
ylabel('Number of occurences')
saveas(gcf,'hist_control_CMS','epsc')


%for CMS instead we need to compute the percentage based on the number of
%websites we observed to have a CMS not the total number of websites in the
%group

[occurences_control,type_control] = histcounts(categorical(hist_control_cms))
percentage_control_cms = (occurences_control*100.0)/sum(occurences_control)
tab_count_cms_control = table(type_control',percentage_control_cms','VariableNames',{'CMS','Percentage'});

[occurences_miners,type_miners] = histcounts(categorical(hist_miners_cms))
percentage_miners_cms = (occurences_miners*100.0)/sum(occurences_miners)
tab_count_cms_case = table(type_miners',percentage_miners_cms','VariableNames',{'CMS','Percentage'});


%bar chart grouped server type
figure;
market_share_cms = [63.3;4.2;3.9;2.8;2.5;2.3;1.7;1.7;1.3;0.9;1.0;0.6;0.6];
control_cms = [];
case_cms = [];
cms_name = categorical(["WordPress","Joomla!","Shopify","Drupal","Squarespace","Wix","Bitrix","Blogger","Magento","PrestaShop","OpenChart","TYPO3","Weebly"]);
for i=1:length(cms_name)
   percentage_control = tab_count_cms_control.('Percentage')(tab_count_cms_control.('CMS')==cms_name(i));
   if isempty(percentage_control)
        control_cms = [control_cms; 0];
   else
        control_cms = [control_cms; percentage_control];
   end
   
   percentage_case = tab_count_cms_case.('Percentage')(tab_count_cms_case.('CMS')==cms_name(i));
   if isempty(percentage_case)
        case_cms = [case_cms; 0];
   else
        case_cms = [case_cms; percentage_case];
   end
end

table_percentage_cms = table(cms_name',market_share_cms,control_cms,case_cms);
%order by market share
table_percentage_cms = sortrows(table_percentage_cms,2,'descend');
bar(reordercats(table_percentage_cms.('Var1'),cellstr(table_percentage_cms.('Var1'))),[table_percentage_cms.('market_share_cms') table_percentage_cms.('control_cms') table_percentage_cms.('case_cms')],'BarWidth', 1);
xlabel('CMS Type')
ylabel('Percentage in the group (%)')
legend('market share','control group', 'case group')
saveas(gcf,'hist_market_cms','epsc')


%compare versions usage for the most deployed CMS -> wordpress
%get list of versions for wordpress miners and control groups
if false
cms_miners_wp_version = table_miners.('cms_version')(strcmp(table_miners.('cms'),'WordPress'));
cms_control_wp_version = table_control.('cms_version')(strcmp(table_control.('cms'),'WordPress'));

%order by version
versions_wp_min = natsortfiles(unique(cms_miners_wp_version));
versions_wp_control = natsortfiles(unique(cms_control_wp_version));

%joint the list
versions_wp = natsortfiles(unique([versions_wp_min;versions_wp_control]));
%count the number of occurences
n_version_min = [];
n_version_control = [];
for i=1:length(versions_wp)
    n_version_min = [n_version_min sum(strcmp(cms_miners_wp_version,versions_wp(i)))];
end

for j=1:length(versions_wp)
    n_version_control = [n_version_control sum(strcmp(cms_control_wp_version,versions_wp(j)))];
end

figure;
hold on;
set(gca,'yscale','log')
scatter(categorical(versions_wp),n_version_min,'r','DisplayName','Miners')
scatter(categorical(versions_wp),n_version_control,'g','DisplayName','Control')
title('CMS WordPress versions case and control')
legend
end

%plot percentage of x_powered_by, server and CMS for which you identified
%the version, not identified and not know at all
detected_server_control = sum(not(string(table_control.('server'))==""));
undetected_server_control = size(table_control,1)-detected_server_control;
detected_version_server_control = sum(not(string(table_control.('server'))=="").*not(string(table_control.('server_version'))==""));
undetected_version_server_control = detected_server_control - detected_version_server_control;

detected_cms_control = sum(not(string(table_control.('cms'))==""));
undetected_cms_control = size(table_control,1)-detected_cms_control; 
detected_version_cms_control = sum(not(string(table_control.('cms'))=="").*not(string(table_control.('cms_version'))==""));
undetected_version_cms_control = detected_cms_control - detected_version_cms_control;

detected_xpower_control = sum(not(string(table_control.('x_powered_by'))==""));
undetected_xpower_control = size(table_control,1)-detected_xpower_control;
detected_version_xpower_control = sum(not(string(table_control.('x_powered_by'))=="").*not(string(table_control.('x_powered_by_version'))==""));
undetected_version_xpower_control = detected_xpower_control - detected_version_xpower_control;

figure;
y = [detected_version_server_control undetected_version_server_control undetected_server_control; detected_version_cms_control undetected_version_cms_control undetected_cms_control; detected_version_xpower_control undetected_version_xpower_control undetected_xpower_control]/size(table_control,1);
h = bar(y,'stacked')
set(h,{'FaceColor'},{[0.6350, 0.0780, 0.1840];[[0.9290, 0.6940, 0.1250]];[0, 0.5, 0]});
legend('Detected version','Undetected version','Software not discovered')
ylabel("Percentage")
yticklabels({'0%','10%','20%','30%','40%','50%','60%','70%','80%','90%','100%'})
xticklabels({'Server','CMS','Application framework'})
saveas(gcf,'discovered_information_control','epsc')

%do the same for the case
detected_server_case = sum(not(string(table_miners.('server'))==""));
undetected_server_case = size(table_miners,1)-detected_server_case;
detected_version_server_case = sum(not(string(table_miners.('server'))=="").*not(string(table_miners.('server_version'))==""));
undetected_version_server_case = detected_server_case - detected_version_server_case;

detected_cms_case = sum(not(string(table_miners.('cms'))==""));
undetected_cms_case = size(table_miners,1)-detected_cms_case; 
detected_version_cms_case = sum(not(string(table_miners.('cms'))=="").*not(string(table_miners.('cms_version'))==""));
undetected_version_cms_case = detected_cms_case - detected_version_cms_case;

detected_xpower_case = sum(not(string(table_miners.('x_powered_by'))==""));
undetected_xpower_case = size(table_miners,1)-detected_xpower_case;
detected_version_xpower_case = sum(not(string(table_miners.('x_powered_by'))=="").*not(string(table_miners.('x_powered_by_version'))==""));
undetected_version_xpower_case = detected_xpower_case - detected_version_xpower_case;

figure;
y = [detected_version_server_case undetected_version_server_case undetected_server_case; detected_version_cms_case undetected_version_cms_case undetected_cms_case; detected_version_xpower_case undetected_version_xpower_case undetected_xpower_case]/size(table_miners,1);
h = bar(y,'stacked')
set(h,{'FaceColor'},{[0.6350, 0.0780, 0.1840];[[0.9290, 0.6940, 0.1250]];[0, 0.5, 0]});
legend('Detected version','Undetected version','Software not discovered')
ylabel("Percentage")
yticklabels({'0%','10%','20%','30%','40%','50%','60%','70%','80%','90%','100%'})
xticklabels({'Server','CMS','Application framework'})
saveas(gcf,'discovered_information_case','epsc')

%% HARDENING WEBSITE
fprintf("\n##########################\n")
% we want to check if the absence of information (hiding O.S., etc.)
% produces a reduction in likely of compromise
%sanitized if there is no info about O.S., server version, x-powered-by and
%the header are set properly e.g. http_only=True, x-xss-protection enabled,
%strict-transport enabled with a number of seconds >0

%even if certain headers are not specific for cryptojacking (e.g. HTTPOnly)
%they shows a certain attention to the possible web attacks (e.g. XSS on
%cookies) i.e. a knowledge of the possible threats
n_hiding_miners = sum(strcmp(table_miners.('server_version'),'').*strcmp(table_miners.('cms_version'),'').*not(strcmp(table_miners.('x_powered_by'),'')).*(strcmp(table_miners.('x_powered_by_version'),'')));
n_hiding_control = sum(strcmp(table_control.('server_version'),'').*strcmp(table_control.('cms_version'),'').*not(strcmp(table_control.('x_powered_by'),'')).*(strcmp(table_control.('x_powered_by_version'),'')));

tmp = not(strcmp(table_miners.('server_version'),''))+not(strcmp(table_miners.('cms_version'),''))+not(strcmp(table_miners.('x_powered_by'),'')).*(not(strcmp(table_miners.('x_powered_by_version'),'')));
n_no_hiding_miners = length(tmp) - sum(tmp==0);

tmp = not(strcmp(table_control.('server_version'),''))+not(strcmp(table_control.('cms_version'),''))+not(strcmp(table_control.('x_powered_by'),'')).*(not(strcmp(table_control.('x_powered_by_version'),'')));
n_no_hiding_control = length(tmp) - sum(tmp==0);

odds_no_hiding = (n_no_hiding_miners*n_hiding_control)/(n_hiding_miners*n_no_hiding_control);
odds_hiding = (n_hiding_miners*n_no_hiding_control)/(n_no_hiding_miners*n_hiding_control);
[CI_95_no_hiding_min,CI_95_no_hiding_max] = compute_CI_95(odds_no_hiding,n_no_hiding_miners,n_no_hiding_control,n_hiding_miners,n_hiding_control);
[CI_95_hiding_min,CI_95_hiding_max] = compute_CI_95(odds_hiding,n_hiding_miners,n_hiding_control,n_no_hiding_miners,n_no_hiding_control);
fprintf("Odds ratio no hiding website: %f CI_95(%f,%f)\n",odds_no_hiding,CI_95_no_hiding_min,CI_95_no_hiding_max);
fprintf("Odds ratio hiding website: %f CI_95(%f,%f)\n",odds_hiding,CI_95_hiding_min,CI_95_hiding_max);

%% ODDS RATIO SERVER AND CMS
fprintf("#####################\n")
%we compare the odds ratio with no CMS
n_noCMS_miners = sum(table_miners.('cms')=="");
n_noCMS_control = sum(table_control.('cms')=="");

n_WP_miners = sum(strcmp(table_miners.('cms'),'WordPress'));
n_WP_control = sum(strcmp(table_control.('cms'),'WordPress'));

n_DP_miners = sum(strcmp(table_miners.('cms'),'Drupal'));
n_DP_control = sum(strcmp(table_control.('cms'),'Drupal'));

n_JM_miners = sum(strcmp(table_miners.('cms'),'Joomla'));
n_JM_control = sum(strcmp(table_control.('cms'),'Joomla'));

n_SP_miners = sum(strcmp(table_miners.('cms'),'Shopify'));
n_SP_control = sum(strcmp(table_control.('cms'),'Shopify'));

n_SS_miners = sum(strcmp(table_miners.('cms'),'Squarespace'));
n_SS_control = sum(strcmp(table_control.('cms'),'Squarespace'));

n_BG_miners = sum(strcmp(table_miners.('cms'),'Blogger'));
n_BG_control = sum(strcmp(table_control.('cms'),'Blogger'));

n_WX_miners = sum(strcmp(table_miners.('cms'),'Wix'));
n_WX_control = sum(strcmp(table_control.('cms'),'Wix'));

odds_WP = (n_WP_miners*n_noCMS_control)/(n_noCMS_miners*n_WP_control);
[CI_95_WP_min,CI_95_WP_max] = compute_CI_95(odds_WP,n_WP_miners,n_WP_control,n_noCMS_miners,n_noCMS_control);
fprintf("Odds ratio WordPress: %f CI_95(%f,%f)\n",odds_WP,CI_95_WP_min,CI_95_WP_max);

odds_DP = (n_DP_miners*n_noCMS_control)/(n_noCMS_miners*n_DP_control);
[CI_95_DP_min,CI_95_DP_max] = compute_CI_95(odds_DP,n_DP_miners,n_DP_control,n_noCMS_miners,n_noCMS_control);
fprintf("Odds ratio Drupal: %f CI_95(%f,%f)\n",odds_DP,CI_95_DP_min,CI_95_DP_max);

odds_JM = (n_JM_miners*n_noCMS_control)/(n_noCMS_miners*n_JM_control);
[CI_95_JM_min,CI_95_JM_max] = compute_CI_95(odds_JM,n_JM_miners,n_JM_control,n_noCMS_miners,n_noCMS_control);
fprintf("Odds ratio Joomla: %f CI_95(%f,%f)\n",odds_JM,CI_95_JM_min,CI_95_JM_max);

odds_SP = (n_SP_miners*n_noCMS_control)/(n_noCMS_miners*n_SP_control);
[CI_95_SP_min,CI_95_SP_max] = compute_CI_95(odds_SP,n_SP_miners,n_SP_control,n_noCMS_miners,n_noCMS_control);
fprintf("Odds ratio Shopify: %f CI_95(%f,%f)\n",odds_SP,CI_95_SP_min,CI_95_SP_max);

odds_SS = (n_SS_miners*n_noCMS_control)/(n_noCMS_miners*n_SS_control);
[CI_95_SS_min,CI_95_SS_max] = compute_CI_95(odds_SS,n_SS_miners,n_SS_control,n_noCMS_miners,n_noCMS_control);
fprintf("Odds ratio Squarespace: %f CI_95(%f,%f)\n",odds_SS,CI_95_SS_min,CI_95_SS_max);

odds_BG = (n_BG_miners*n_noCMS_control)/(n_noCMS_miners*n_BG_control);
[CI_95_BG_min,CI_95_BG_max] = compute_CI_95(odds_BG,n_BG_miners,n_BG_control,n_noCMS_miners,n_noCMS_control);
fprintf("Odds ratio Blogger: %f CI_95(%f,%f)\n",odds_BG,CI_95_BG_min,CI_95_BG_max);

odds_WX = (n_WX_miners*n_noCMS_control)/(n_noCMS_miners*n_WX_control);
[CI_95_WX_min,CI_95_WX_max] = compute_CI_95(odds_WX,n_WX_miners,n_WX_control,n_noCMS_miners,n_noCMS_control);
fprintf("Odds ratio Wix: %f CI_95(%f,%f)\n",odds_WX,CI_95_WX_min,CI_95_WX_max);

fprintf("\n##########################\n")
%we compare the odds ratio with the most popular web server we observed in the control (Apache)
%https://w3techs.com/technologies/overview/web_server
%this is my base case
n_apache_miners = sum(strcmp(table_miners.('server'),'apache'));
n_apache_control = sum(strcmp(table_control.('server'),'apache'));

n_cloudflare_miners = sum(strcmp(table_miners.('server'),'cloudflare'));
n_cloudflare_control = sum(strcmp(table_control.('server'),'cloudflare'));

n_litespeed_miners = sum(strcmp(table_miners.('server'),'litespeed'));
n_litespeed_control = sum(strcmp(table_control.('server'),'litespeed'));

n_microsoftIIS_miners = sum(strcmp(table_miners.('server'),'microsoft-IIS'));
n_microsoftIIS_control = sum(strcmp(table_control.('server'),'microsoft-IIS'));

n_nginx_miners = sum(strcmp(table_miners.('server'),'nginx')); 
n_nginx_control = sum(strcmp(table_control.('server'),'nginx'));

n_openresty_miners = sum(strcmp(table_miners.('server'),'openresty')); 
n_openresty_control = sum(strcmp(table_control.('server'),'openresty')); 

odds_cloudflare = (n_cloudflare_miners*n_apache_control)/(n_apache_miners*n_cloudflare_control);
[CI_95_cloudflare_min,CI_95_cloudflare_max] = compute_CI_95(odds_cloudflare,n_cloudflare_miners,n_cloudflare_control,n_apache_miners,n_apache_control);
fprintf("Odds ratio Cloudflare: %f CI_95(%f,%f)\n",odds_cloudflare,CI_95_cloudflare_min,CI_95_cloudflare_max);

odds_litespeed = (n_litespeed_miners*n_apache_control)/(n_apache_miners*n_litespeed_control);
[CI_95_litespeed_min,CI_95_litespeed_max] = compute_CI_95(odds_litespeed,n_litespeed_miners,n_litespeed_control,n_apache_miners,n_apache_control);
fprintf("Odds ratio Litespeed: %f CI_95(%f,%f)\n",odds_litespeed,CI_95_litespeed_min,CI_95_litespeed_max);

odds_microsoftIIS = (n_microsoftIIS_miners*n_apache_control)/(n_apache_miners*n_microsoftIIS_control);
[CI_95_microsoftIIS_min,CI_95_microsoftIIS_max] = compute_CI_95(odds_microsoftIIS,n_microsoftIIS_miners,n_microsoftIIS_control,n_apache_miners,n_apache_control);
fprintf("Odds ratio Microsoft-IIS: %f CI_95(%f,%f)\n",odds_microsoftIIS,CI_95_microsoftIIS_min,CI_95_microsoftIIS_max);

odds_nginx = (n_nginx_miners*n_apache_control)/(n_apache_miners*n_nginx_control);
[CI_95_nginx_min,CI_95_nginx_max] = compute_CI_95(odds_nginx,n_nginx_miners,n_nginx_control,n_apache_miners,n_apache_control);
fprintf("Odds ratio Nginx: %f CI_95(%f,%f)\n",odds_nginx,CI_95_nginx_min,CI_95_nginx_max);

odds_openresty = (n_openresty_miners*n_apache_control)/(n_apache_miners*n_openresty_control);
[CI_95_openresty_min,CI_95_openresty_max] = compute_CI_95(odds_openresty,n_openresty_miners,n_openresty_control,n_apache_miners,n_apache_control);
fprintf("Odds ratio Openresty: %f CI_95(%f,%f)\n",odds_openresty,CI_95_openresty_min,CI_95_openresty_max);