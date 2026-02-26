/**
 * OpenClaw V3.2 - Self-Play Mechanism
 * 策略引擎核心模块：自我博弈机制
 *
 * 功能：
 * - 策略对决算法
 * - 历史胜率统计
 * - 策略学习优化
 *
 * @author OpenClaw V3.2
 * @date 2026-02-21
 */

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

class SelfPlayMechanism {
  constructor() {
    this.name = 'SelfPlayMechanism';
    this.gameHistory = [];
    this.strategyStats = new Map();
    this.learnings = new Map();
  }

  /**
   * 模拟对局
   * @param {Object} params
   * @returns {Promise<MatchResult>}
   */
  async playMatch(params) {
    const { strategyA, strategyB, rounds = 100 } = params;

    console.log(`[SelfPlayMechanism] 策略对决: ${strategyA.name} vs ${strategyB.name}`);

    const results = {
      strategyA: { name: strategyA.name, wins: 0, losses: 0, draws: 0 },
      strategyB: { name: strategyB.name, wins: 0, losses: 0, draws: 0 },
      matchResults: [],
      bestOf: this.determineBestOf(rounds)
    };

    for (let i = 0; i < rounds; i++) {
      const result = await this.playRound({
        strategyA,
        strategyB,
        scenario: this.generateScenario(),
        matchResults: results.matchResults
      });

      results.matchResults.push(result);

      if (result.winner === 'A') {
        results.strategyA.wins++;
        this.recordWin(strategyA.name);
      } else if (result.winner === 'B') {
        results.strategyB.wins++;
        this.recordWin(strategyB.name);
      } else {
        results.strategyA.draws++;
        results.strategyB.draws++;
        this.recordDraw(strategyA.name);
        this.recordDraw(strategyB.name);
      }

      // 每10回合输出进度
      if ((i + 1) % 10 === 0) {
        console.log(`[SelfPlayMechanism] 进度: ${i + 1}/${rounds}`);
      }

      await sleep(5);
    }

    const winner = this.determineWinner(results);

    return {
      ...results,
      winner,
      learnings: this.extractLearnings(results),
      timestamp: new Date()
    };
  }

  /**
   * 执行单回合对局
   */
  async playRound(params) {
    const { strategyA, strategyB, scenario, matchResults } = params;

    // 策略A 执行
    const resultA = await strategyA.execute(scenario);

    // 策略B 执行
    const resultB = await strategyB.execute(scenario);

    // 计算得分
    const scoreA = this.calculateScore(resultA, scenario);
    const scoreB = this.calculateScore(resultB, scenario);

    // 确定胜者
    const winner = scoreA > scoreB ? 'A' : (scoreB > scoreA ? 'B' : 'draw');

    return {
      round: matchResults.length + 1,
      scenario: {
        ...scenario,
        timestamp: new Date()
      },
      resultA: {
        ...resultA,
        score: scoreA
      },
      resultB: {
        ...resultB,
        score: scoreB
      },
      winner
    };
  }

  /**
   * 生成测试场景
   */
  generateScenario() {
    const complexityLevels = [0.3, 0.5, 0.7];
    const contextLengths = [20000, 40000, 60000];
    const errorRates = [0.02, 0.05, 0.1];

    const complexity = complexityLevels[Math.floor(Math.random() * complexityLevels.length)];
    const contextLength = contextLengths[Math.floor(Math.random() * contextLengths.length)];
    const errorRate = errorRates[Math.floor(Math.random() * errorRates.length)];

    return {
      complexity,
      contextLength,
      errorRate,
      randomSeed: Math.random()
    };
  }

  /**
   * 计算得分
   */
  async calculateScore(result, scenario) {
    // 评分标准：质量 30% + 成功率 30% + 用户满意度 20% + 效率 20%
    const quality = result.quality || 0.9;
    const successRate = result.successRate || 0.9;
    const userSatisfaction = result.userSatisfaction || 0.88;
    const efficiency = result.efficiency || 0.9;

    return (
      quality * 0.3 +
      successRate * 0.3 +
      userSatisfaction * 0.2 +
      efficiency * 0.2
    );
  }

  /**
   * 确定最佳局数
   */
  determineBestOf(rounds) {
    // 找最接近的奇数
    return rounds % 2 === 0 ? rounds + 1 : rounds;
  }

  /**
   * 确定胜者
   */
  determineWinner(results) {
    if (results.strategyA.wins > results.strategyB.wins) {
      return 'A';
    }
    if (results.strategyB.wins > results.strategyA.wins) {
      return 'B';
    }
    return 'draw';
  }

  /**
   * 记录胜利
   */
  recordWin(strategyName) {
    const stats = this.strategyStats.get(strategyName) || { wins: 0, total: 0 };
    stats.wins++;
    stats.total++;
    this.strategyStats.set(strategyName, stats);
  }

  /**
   * 记录平局
   */
  recordDraw(strategyName) {
    const stats = this.strategyStats.get(strategyName) || { wins: 0, draws: 0, total: 0 };
    stats.draws++;
    stats.total++;
    this.strategyStats.set(strategyName, stats);
  }

  /**
   * 提取学习见解
   */
  extractLearnings(results) {
    const learnings = [];

    // 分析胜率分布
    if (results.strategyA.wins > results.strategyB.wins) {
      learnings.push({
        strategy: 'A',
        insight: '在当前场景下表现更好',
        evidence: `${results.strategyA.wins}胜 vs ${results.strategyB.wins}负`
      });
    } else if (results.strategyB.wins > results.strategyA.wins) {
      learnings.push({
        strategy: 'B',
        insight: '在当前场景下表现更好',
        evidence: `${results.strategyB.wins}胜 vs ${results.strategyA.wins}负`
      });
    }

    // 分析不同复杂度的表现
    const byComplexity = this.groupByComplexity(results.matchResults);

    for (const [complexity, matches] of byComplexity) {
      const scoreA = matches.filter(m => m.winner === 'A').length;
      const scoreB = matches.filter(m => m.winner === 'B').length;

      if (scoreA > scoreB) {
        learnings.push({
          strategy: 'A',
          insight: `在复杂度 ${complexity} 场景下占优`,
          evidence: `A胜${scoreA} vs B胜${scoreB}`
        });
      } else if (scoreB > scoreA) {
        learnings.push({
          strategy: 'B',
          insight: `在复杂度 ${complexity} 场景下占优`,
          evidence: `B胜${scoreB} vs A胜${scoreA}`
        });
      }
    }

    return learnings;
  }

  /**
   * 按复杂度分组
   */
  groupByComplexity(results) {
    const grouped = new Map();

    for (const match of results) {
      const complexity = match.scenario.complexity.toFixed(1);
      if (!grouped.has(complexity)) {
        grouped.set(complexity, []);
      }
      grouped.get(complexity).push(match);
    }

    return grouped;
  }

  /**
   * 训练多个策略
   * @param {Array<Object>} strategies - 策略对象列表
   * @param {number} rounds - 每对策略的回合数
   * @returns {Promise<TrainingResult>}
   */
  async train(strategies, rounds = 100) {
    console.log(`[SelfPlayMechanism] 开始训练 ${strategies.length} 个策略`);

    const allStrategies = Array.from(strategies);
    const matches = [];

    // 两两对决
    for (let i = 0; i < allStrategies.length; i++) {
      for (let j = i + 1; j < allStrategies.length; j++) {
        const match = await this.playMatch({
          strategyA: allStrategies[i],
          strategyB: allStrategies[j],
          rounds
        });

        matches.push(match);
      }
    }

    // 统计胜率
    const stats = this.calculateStatistics(matches);

    return {
      matches,
      stats,
      learnings: this.extractLearningPatterns(matches),
      timestamp: new Date()
    };
  }

  /**
   * 计算统计信息
   */
  calculateStatistics(matches) {
    const stats = new Map();

    // 计算每个策略的统计
    for (const match of matches) {
      if (match.winner === 'A') {
        this.updateStats(stats, match.strategyA.name, 'wins');
      } else if (match.winner === 'B') {
        this.updateStats(stats, match.strategyB.name, 'wins');
      }

      if (match.winner === 'A') {
        this.updateStats(stats, match.strategyA.name, 'played');
      } else if (match.winner === 'B') {
        this.updateStats(stats, match.strategyB.name, 'played');
      } else {
        this.updateStats(stats, match.strategyA.name, 'draws');
        this.updateStats(stats, match.strategyB.name, 'draws');
      }
    }

    return {
      totalMatches: matches.length,
      strategyStats: Object.fromEntries(stats),
      overallWinRate: this.calculateOverallWinRate(stats)
    };
  }

  /**
   * 更新统计
   */
  updateStats(stats, strategyName, type) {
    if (!stats.has(strategyName)) {
      stats.set(strategyName, {
        wins: 0,
        draws: 0,
        played: 0,
        totalGames: 0
      });
    }

    const stat = stats.get(strategyName);
    if (type === 'wins') {
      stat.wins++;
    } else if (type === 'draws') {
      stat.draws++;
    }
    stat.played++;
    stat.totalGames++;
  }

  /**
   * 计算整体胜率
   */
  calculateOverallWinRate(stats) {
    let totalWins = 0;
    let totalGames = 0;

    for (const [name, stat] of stats) {
      totalWins += stat.wins;
      totalGames += stat.played;
    }

    return totalGames > 0 ? totalWins / totalGames : 0;
  }

  /**
   * 提取学习模式
   */
  extractLearningPatterns(matches) {
    const patterns = new Map();

    // 分析最佳场景
    const bestScenario = this.findBestScenario(matches);

    // 分析最差场景
    const worstScenario = this.findWorstScenario(matches);

    return {
      bestScenario,
      worstScenario,
      patterns: Array.from(patterns)
    };
  }

  /**
   * 找到最佳场景
   */
  findBestScenario(matches) {
    let bestScore = -1;
    let bestScenario = null;

    for (const match of matches) {
      const scoreA = match.resultA.score;
      const scoreB = match.resultB.score;

      if (scoreA > scoreB && scoreA > bestScore) {
        bestScore = scoreA;
        bestScenario = {
          scenario: match.scenario,
          winner: 'A',
          score: scoreA,
          result: match.resultA
        };
      } else if (scoreB > scoreA && scoreB > bestScore) {
        bestScore = scoreB;
        bestScenario = {
          scenario: match.scenario,
          winner: 'B',
          score: scoreB,
          result: match.resultB
        };
      }
    }

    return bestScenario;
  }

  /**
   * 找到最差场景
   */
  findWorstScenario(matches) {
    let worstScore = Infinity;
    worstScenario = null;

    for (const match of matches) {
      const scoreA = match.resultA.score;
      const scoreB = match.resultB.score;

      if (scoreA < scoreB && scoreA < worstScore) {
        worstScore = scoreA;
        worstScenario = {
          scenario: match.scenario,
          loser: 'A',
          score: scoreA,
          result: match.resultA
        };
      } else if (scoreB < scoreA && scoreB < worstScore) {
        worstScore = scoreB;
        worstScenario = {
          scenario: match.scenario,
          loser: 'B',
          score: scoreB,
          result: match.resultB
        };
      }
    }

    return worstScenario;
  }
}

module.exports = SelfPlayMechanism;
