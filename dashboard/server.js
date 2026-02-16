/**
 * OpenClaw Dashboard Server
 * Express服务器 + API路由 + 中间件
 */

const express = require('express');
const path = require('path');
const config = require('./config');
const cacheMiddleware = require('./middlewares/cache');
const errorHandler = require('./middlewares/error');

class DashboardServer {
  constructor(options = {}) {
    this.port = options.port || config.port;
    this.apiPrefix = options.apiPrefix || config.apiPrefix;
    this.cacheTime = options.cacheTime || config.cacheTime;
    this.app = express();
    this.server = null;

    this.setupMiddleware();
    this.setupRoutes();
    this.setupHealthCheck();
  }

  /**
   * 设置中间件
   */
  setupMiddleware() {
    // JSON解析
    this.app.use(express.json());

    // URL编码
    this.app.use(express.urlencoded({ extended: true }));

    // 静态文件服务
    this.app.use(express.static(path.join(__dirname, '../public')));

    this.app.use(express.static(path.join(__dirname, '../dashboard')));
  }

  /**
   * 设置路由
   */
  setupRoutes() {
    // API路由
    this.app.use(`${this.apiPrefix}/data`, this.routes);
  }

  /**
   * 路由处理
   */
  get routes() {
    const router = express.Router();

    // 获取所有数据
    router.get('/all', cacheMiddleware(this.cacheTime), this.getAllData.bind(this));

    // 获取特定数据
    router.get('/:dataType', cacheMiddleware(this.cacheTime), this.getDataType.bind(this));

    // 获取实时数据
    router.get('/realtime/:dataType', this.getRealtimeData.bind(this));

    return router;
  }

  /**
   * 获取所有数据
   */
  async getAllData(req, res, next) {
    try {
      const dashboardController = require('./controllers/dashboard');
      const data = await dashboardController.getAllData();
      res.json({
        success: true,
        data,
        timestamp: Date.now()
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 获取特定类型数据
   */
  async getDataType(req, res, next) {
    try {
      const { dataType } = req.params;
      const dashboardController = require('./controllers/dashboard');
      const data = await dashboardController.getDataByType(dataType);
      res.json({
        success: true,
        data,
        timestamp: Date.now()
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 获取实时数据
   */
  async getRealtimeData(req, res, next) {
    try {
      const { dataType } = req.params;
      const dashboardController = require('./controllers/dashboard');
      const data = await dashboardController.getRealtimeData(dataType);
      res.json({
        success: true,
        data,
        timestamp: Date.now()
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 设置健康检查
   */
  setupHealthCheck() {
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: Date.now()
      });
    });
  }

  /**
   * 启动服务器
   */
  start() {
    return new Promise((resolve, reject) => {
      this.server = this.app.listen(this.port, () => {
        console.log(`Dashboard Server started on port ${this.port}`);
        console.log(`API prefix: ${this.apiPrefix}`);
        resolve(this.server);
      });

      this.server.on('error', (error) => {
        reject(error);
      });
    });
  }

  /**
   * 停止服务器
   */
  async stop() {
    return new Promise((resolve) => {
      if (this.server) {
        this.server.close(() => {
          console.log('Dashboard Server stopped');
          resolve();
        });
      } else {
        resolve();
      }
    });
  }

  /**
   * 获取应用实例
   */
  getApp() {
    return this.app;
  }
}

module.exports = DashboardServer;
