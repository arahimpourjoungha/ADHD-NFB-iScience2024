classdef MockChannelStats
    %MOCKCHANNELSTATS  Stand-in for nirs.core.ChannelStats, for tests only.
    %
    %   HboGenerateTableAveTwo checks isprop(ARStats(1,i), ...), which is
    %   false for structs, so the mock has to be a class. It mimics only
    %   what that script touches:
    %     demographics.values  cell; {1,8} subject ID, {1,9} 'Intervention<k>'
    %     description          char, contains 'NFB' or 'WL'
    %     beta                 column vector of GLM betas

    properties
        demographics = struct('values', {{}})
        description = ''
        beta = []
    end

    methods
        function obj = MockChannelStats(values, description, beta)
            if nargin > 0
                obj.demographics = struct('values', {values});
                obj.description = description;
                obj.beta = beta;
            end
        end
    end
end
