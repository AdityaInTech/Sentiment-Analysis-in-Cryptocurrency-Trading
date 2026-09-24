% function [sentimentResults, cryptoDataUpdated] = analyze_sentiment(cryptoDataInput, zWindow)
% % ANALYZE_SENTIMENT Preprocesses text, computes VADER-like scores, Rolling Z-Score & Velocity.
% %
% % Syntax:
% %   [sentimentResults, cryptoDataUpdated] = analyze_sentiment(cryptoDataInput)
% %   [sentimentResults, cryptoDataUpdated] = analyze_sentiment(cryptoDataInput, zWindow)
% %
% % Inputs:
% %   cryptoDataInput - MATLAB table containing 'Headlines' or 'SentimentRaw'
% %   zWindow         - Rolling window for Z-score calculation (default: 24 hours)
% %
% % Outputs:
% %   sentimentResults  - MATLAB table containing sentiment metrics:
% %                       PosScore, NegScore, NeuScore, CompoundScore, SentimentZScore, SentimentVelocity
% %   cryptoDataUpdated - Input table augmented with sentiment metrics.
% %
% % Author: Senior Quantitative Trader & Financial Engineer
% % Project: Comprehensive Quantitative Crypto Trading System
% 
%     if nargin < 2 || isempty(zWindow)
%         zWindow = 24; % 24-hour rolling window
%     end
% 
%     % Extract text or pre-generated sentiment raw score
%     if istable(cryptoDataInput)
%         if ismember('SentimentRaw', cryptoDataInput.Properties.VariableNames)
%             compoundScores = cryptoDataInput.SentimentRaw;
%             headlines = cryptoDataInput.Headlines;
%         elseif ismember('Headlines', cryptoDataInput.Properties.VariableNames)
%             headlines = cryptoDataInput.Headlines;
%             compoundScores = [];
%         else
%             error('Input table must contain Headlines or SentimentRaw column.');
%         end
%     elseif iscell(cryptoDataInput) || isstring(cryptoDataInput)
%         headlines = cryptoDataInput;
%         compoundScores = [];
%     elseif isnumeric(cryptoDataInput)
%         compoundScores = cryptoDataInput;
%         headlines = {};
%     else
%         error('Invalid input format for analyze_sentiment.');
%     end
% 
%     numEntries = max(length(headlines), length(compoundScores));
%     posScores = zeros(numEntries, 1);
%     negScores = zeros(numEntries, 1);
%     neuScores = zeros(numEntries, 1);
% 
%     % If CompoundScore is not yet computed, process text using VADER NLP Lexicon
%     if isempty(compoundScores)
%         compoundScores = zeros(numEntries, 1);
% 
%         lexiconKeys = { ...
%             'bullish', 'moon', 'rally', 'skyrocket', 'breakout', 'buy', 'buying', 'adoption', ...
%             'inflow', 'gain', 'upward', 'green', 'ath', 'accumulation', 'hodl', 'rewarded', ...
%             'positive', 'profit', 'surge', 'outperform', 'greedy', 'support', 'good', 'great', ...
%             'bearish', 'dump', 'crash', 'plummet', 'fud', 'scam', 'sell', 'selling', ...
%             'crackdown', 'panic', 'exploit', 'headwinds', 'down', 'red', 'liquidation', ...
%             'hack', 'warning', 'loss', 'risk', 'fear', 'correction', 'investigation' ...
%         };
% 
%         lexiconValues = [ ...
%             0.80,  0.90,  0.70,  0.85,  0.75,  0.50,  0.50,  0.60, ...
%             0.60,  0.50,  0.50,  0.40,  0.80,  0.60,  0.60,  0.50, ...
%             0.50,  0.60,  0.70,  0.60,  0.50,  0.30,  0.40,  0.50, ...
%            -0.80, -0.85, -0.90, -0.85, -0.60, -0.90, -0.50, -0.50, ...
%            -0.70, -0.80, -0.80, -0.50, -0.40, -0.40, -0.70, ...
%            -0.85, -0.50, -0.60, -0.40, -0.70, -0.50, -0.60  ...
%         ];
% 
%         lexiconMap = containers.Map(lexiconKeys, lexiconValues);
% 
%         stopWords = {'the', 'a', 'an', 'and', 'or', 'is', 'are', 'was', 'were', 'be', 'been', ...
%                      'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from', 'up', 'about', ...
%                      'into', 'over', 'after', 'as', 'it', 'this', 'that', 'these', 'those', 'am'};
%         stopWordsSet = containers.Map(stopWords, true(1, length(stopWords)));
%         negationWords = {'not', 'no', 'never', 'neither', 'nor', 'without', 'cannot', 'cant', 'dont'};
% 
%         for i = 1:numEntries
%             rawText = string(headlines{i});
%             cleanText = lower(rawText);
%             cleanText = regexprep(cleanText, '[^\w\s]', ' ');
%             tokens = split(cleanText);
%             tokens(strlength(tokens) == 0) = [];
% 
%             if isempty(tokens)
%                 neuScores(i) = 1.0;
%                 continue;
%             end
% 
%             totalTokens = length(tokens);
%             posCount = 0; negCount = 0; neuCount = 0;
%             rawValenceSum = 0;
% 
%             for k = 1:totalTokens
%                 word = char(tokens(k));
%                 if isKey(stopWordsSet, word)
%                     neuCount = neuCount + 1;
%                     continue;
%                 end
%                 if isKey(lexiconMap, word)
%                     score = lexiconMap(word);
%                     if k > 1
%                         prevWord = char(tokens(k-1));
%                         if ismember(prevWord, negationWords)
%                             score = score * -0.8;
%                         end
%                     end
%                     rawValenceSum = rawValenceSum + score;
%                     if score > 0;     posCount = posCount + 1;
%                     elseif score < 0; negCount = negCount + 1;
%                     else;             neuCount = neuCount + 1;
%                     end
%                 else
%                     neuCount = neuCount + 1;
%                 end
%             end
% 
%             posScores(i) = posCount / totalTokens;
%             negScores(i) = negCount / totalTokens;
%             neuScores(i) = neuCount / totalTokens;
% 
%             alpha = 15;
%             compoundScores(i) = rawValenceSum / sqrt(rawValenceSum^2 + alpha);
%         end
%     else
%         % Infer pos/neg/neu proportions from given compound scores
%         posScores = max(0, compoundScores);
%         negScores = abs(min(0, compoundScores));
%         neuScores = 1 - (posScores + negScores);
%     end
% 
%     % 1. Compute 24-Hour Rolling Sentiment Z-Score
%     % Z_t = (S_t - mean_24h) / (std_24h + eps)
%     rollMean = movmean(compoundScores, [zWindow - 1, 0]);
%     rollStd  = movstd(compoundScores, [zWindow - 1, 0]);
% 
%     sentimentZScore = (compoundScores - rollMean) ./ (rollStd + 1e-5);
%     sentimentZScore = max(-3.5, min(3.5, sentimentZScore)); % Clamp to [-3.5, +3.5]
% 
%     % 2. Compute Sentiment Velocity (dSentiment / dt = Z_t - Z_{t-1})
%     sentimentVelocity = [0; diff(sentimentZScore)];
% 
%     % Package into output Table
%     sentimentResults = table(posScores, negScores, neuScores, compoundScores, sentimentZScore, sentimentVelocity, ...
%         'VariableNames', {'PosScore', 'NegScore', 'NeuScore', 'CompoundScore', 'SentimentZScore', 'SentimentVelocity'});
% 
%     if istable(cryptoDataInput)
%         % Avoid duplicate column names if re-running
%         varNames = sentimentResults.Properties.VariableNames;
%         for v = 1:length(varNames)
%             if ismember(varNames{v}, cryptoDataInput.Properties.VariableNames)
%                 cryptoDataInput.(varNames{v}) = [];
%             end
%         end
%         cryptoDataUpdated = [cryptoDataInput, sentimentResults];
%     else
%         cryptoDataUpdated = sentimentResults;
%     end
% 
%     fprintf('[INFO] Sentiment analysis complete (Z-Score & Velocity over %d-hr window).\n', zWindow);
% end


function [sentimentResults, cryptoDataUpdated] = analyze_sentiment(cryptoDataInput, zWindow, coinSymbol)
% ANALYZE_SENTIMENT Preprocesses text, computes VADER-like scores, Rolling Z-Score & Velocity.
%
% Syntax:
%   [sentimentResults, cryptoDataUpdated] = analyze_sentiment(cryptoDataInput)
%   [sentimentResults, cryptoDataUpdated] = analyze_sentiment(cryptoDataInput, zWindow)
%   [sentimentResults, cryptoDataUpdated] = analyze_sentiment(cryptoDataInput, zWindow, coinSymbol)

    if nargin < 2 || isempty(zWindow)
        zWindow = 24; % 24-hour rolling window
    end

    if nargin < 3 || isempty(coinSymbol)
        coinSymbol = 'BTC';
    end

    % Extract text or pre-generated sentiment raw score
    if istable(cryptoDataInput)
        if ismember('SentimentRaw', cryptoDataInput.Properties.VariableNames)
            compoundScores = cryptoDataInput.SentimentRaw;
            if ismember('Headlines', cryptoDataInput.Properties.VariableNames)
                headlines = cryptoDataInput.Headlines;
            elseif ismember('Text', cryptoDataInput.Properties.VariableNames)
                headlines = cryptoDataInput.Text;
            else
                headlines = {};
            end
        elseif ismember('Headlines', cryptoDataInput.Properties.VariableNames)
            headlines = cryptoDataInput.Headlines;
            compoundScores = [];
        elseif ismember('Text', cryptoDataInput.Properties.VariableNames)
            headlines = cryptoDataInput.Text;
            compoundScores = [];
        else
            error('Input table must contain Headlines, Text, or SentimentRaw column.');
        end
    elseif iscell(cryptoDataInput) || isstring(cryptoDataInput)
        headlines = cryptoDataInput;
        compoundScores = [];
    elseif isnumeric(cryptoDataInput)
        compoundScores = cryptoDataInput;
        headlines = {};
    else
        error('Invalid input format for analyze_sentiment.');
    end

    numEntries = max(length(headlines), length(compoundScores));
    posScores = zeros(numEntries, 1);
    negScores = zeros(numEntries, 1);
    neuScores = zeros(numEntries, 1);

    % If CompoundScore is not yet computed, process text using VADER NLP Lexicon
    if isempty(compoundScores)
        compoundScores = zeros(numEntries, 1);

        % Financial & Crypto Sentiment Lexicon
        lexiconKeys = { ...
            'bullish', 'moon', 'rally', 'skyrocket', 'breakout', 'buy', 'buying', 'adoption', ...
            'inflow', 'gain', 'upward', 'green', 'ath', 'accumulation', 'hodl', 'rewarded', ...
            'positive', 'profit', 'surge', 'outperform', 'greedy', 'support', 'good', 'great', ...
            'bearish', 'dump', 'crash', 'plummet', 'fud', 'scam', 'sell', 'selling', ...
            'crackdown', 'panic', 'exploit', 'headwinds', 'down', 'red', 'liquidation', ...
            'hack', 'warning', 'loss', 'risk', 'fear', 'correction', 'investigation' ...
        };

        lexiconValues = [ ...
            0.80,  0.90,  0.70,  0.85,  0.75,  0.50,  0.50,  0.60, ...
            0.60,  0.50,  0.50,  0.40,  0.80,  0.60,  0.60,  0.50, ...
            0.50,  0.60,  0.70,  0.60,  0.50,  0.30,  0.40,  0.50, ...
           -0.80, -0.85, -0.90, -0.85, -0.60, -0.90, -0.50, -0.50, ...
           -0.70, -0.80, -0.80, -0.50, -0.40, -0.40, -0.70, ...
           -0.85, -0.50, -0.60, -0.40, -0.70, -0.50, -0.60  ...
        ];

        lexiconMap = containers.Map(lexiconKeys, lexiconValues);

        stopWords = {'the', 'a', 'an', 'and', 'or', 'is', 'are', 'was', 'were', 'be', 'been', ...
                     'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from', 'up', 'about', ...
                     'into', 'over', 'after', 'as', 'it', 'this', 'that', 'these', 'those', 'am'};
        stopWordsSet = containers.Map(stopWords, true(1, length(stopWords)));
        negationWords = {'not', 'no', 'never', 'neither', 'nor', 'without', 'cannot', 'cant', 'dont'};

        for i = 1:numEntries
            rawText = string(headlines{i});
            cleanText = lower(rawText);
            cleanText = regexprep(cleanText, '[^\w\s]', ' ');
            tokens = split(cleanText);
            tokens(strlength(tokens) == 0) = [];

            if isempty(tokens)
                neuScores(i) = 1.0;
                continue;
            end

            totalTokens = length(tokens);
            posCount = 0; negCount = 0; neuCount = 0;
            rawValenceSum = 0;

            for k = 1:totalTokens
                word = char(tokens(k));
                if isKey(stopWordsSet, word)
                    neuCount = neuCount + 1;
                    continue;
                end
                if isKey(lexiconMap, word)
                    score = lexiconMap(word);
                    if k > 1
                        prevWord = char(tokens(k-1));
                        if ismember(prevWord, negationWords)
                            score = score * -0.8;
                        end
                    end
                    rawValenceSum = rawValenceSum + score;
                    if score > 0;     posCount = posCount + 1;
                    elseif score < 0; negCount = negCount + 1;
                    else;             neuCount = neuCount + 1;
                    end
                else
                    neuCount = neuCount + 1;
                end
            end

            posScores(i) = posCount / totalTokens;
            negScores(i) = negCount / totalTokens;
            neuScores(i) = neuCount / totalTokens;

            alpha = 15;
            compoundScores(i) = rawValenceSum / sqrt(rawValenceSum^2 + alpha);
        end
    else
        posScores = max(0, compoundScores);
        negScores = abs(min(0, compoundScores));
        neuScores = 1 - (posScores + negScores);
    end

    % 1. Compute 24-Hour Rolling Sentiment Z-Score
    rollMean = movmean(compoundScores, [zWindow - 1, 0]);
    rollStd  = movstd(compoundScores, [zWindow - 1, 0]);

    sentimentZScore = (compoundScores - rollMean) ./ (rollStd + 1e-5);
    sentimentZScore = max(-3.5, min(3.5, sentimentZScore)); % Clamp to [-3.5, +3.5]

    % 2. Compute Sentiment Velocity
    sentimentVelocity = [0; diff(sentimentZScore)];

    % Package into output Table
    sentimentResults = table(posScores, negScores, neuScores, compoundScores, sentimentZScore, sentimentVelocity, ...
        'VariableNames', {'PosScore', 'NegScore', 'NeuScore', 'CompoundScore', 'SentimentZScore', 'SentimentVelocity'});

    if istable(cryptoDataInput)
        varNames = sentimentResults.Properties.VariableNames;
        for v = 1:length(varNames)
            if ismember(varNames{v}, cryptoDataInput.Properties.VariableNames)
                cryptoDataInput.(varNames{v}) = [];
            end
        end
        cryptoDataUpdated = [cryptoDataInput, sentimentResults];
    else
        cryptoDataUpdated = sentimentResults;
    end

    fprintf('[INFO] Sentiment analysis complete for %s (Z-Score & Velocity over %d-hr window).\n', coinSymbol, zWindow);
end