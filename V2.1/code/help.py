import os
import math
import time
import numpy
from IPython import display
import matplotlib.pyplot as plt
import matplotlib_inline
import shutil
import collections
import torch
from torch import nn


#返回所有可用的GPU，如果没有GPU，则返回[cpu(),]
def try_all_gpus():
    devices = [torch.device(f'cuda:{i}') for i in range(torch.cuda.device_count())]
    return devices if devices else [torch.device('cpu')]

#记录多次运行时间
class Timer:
    def __init__(self):
        self.times = []
        self.start()
    def start(self):
        """启动计时器"""
        self.tik = time.time()
    def stop(self):
        """停止计时器并将时间记录在列表中"""
        self.times.append(time.time() - self.tik)
        return self.times[-1]
    def avg(self):
        """返回平均时间"""
        return sum(self.times) / len(self.times)
    def sum(self):
        """返回时间总和"""
        return sum(self.times)
    def cumsum(self):
        """返回累计时间"""
        return numpy.array(self.times).cumsum().tolist()
    
#设置matplotlib的图表大小
def set_figsize(figsize=(3.5, 2.5)):
    plt.rcParams['figure.figsize'] = figsize

#设置matplotlib的轴
def set_axes(axes, xlabel, ylabel, xlim, ylim, xscale, yscale, legend):
    #轴的文字标签
    axes.set_xlabel(xlabel)
    axes.set_ylabel(ylabel)
    #轴的刻度类型
    axes.set_xscale(xscale)
    axes.set_yscale(yscale)
    #轴的显示范围
    if xlim:
        axes.set_xlim(xlim)
    if ylim:
        axes.set_ylim(ylim)
    #图例
    if legend:
        axes.legend(legend)
    # 显示网格线
    axes.grid()

def use_svg_display():
    """使用svg格式在Jupyter中显示绘图"""
    matplotlib_inline.backend_inline.set_matplotlib_formats('svg')


# 动画器绘制数据图线
class Animator:
    def __init__(self, xlabel=None, ylabel=None, legend=None,      xlim=None,
        ylim=None, xscale='linear', yscale='linear',
    fmts=('-', 'm--', 'g-.', 'r:'), nrows=1, ncols=1,
    figsize=(3.5, 2.5)):
        # 增量地绘制多条线
        if legend is None:
            legend = []
        use_svg_display()
        self.fig, self.axes = plt.subplots(nrows, ncols, figsize=figsize)
        if nrows * ncols == 1:
            self.axes = [self.axes, ]
        # 使用lambda函数捕获参数
        self.config_axes = lambda: set_axes(self.axes[0], xlabel, ylabel, xlim, ylim, xscale, yscale, legend)
        self.X, self.Y, self.fmts = None, None, fmts

    def add(self, x, y):
        # 向图表中添加多个数据点
        if not hasattr(y, "__len__"):
            y = [y]
        n = len(y)
        if not hasattr(x, "__len__"):
            x = [x] * n
        if not self.X:
            self.X = [[] for _ in range(n)]
        if not self.Y:
            self.Y = [[] for _ in range(n)]
        for i, (a, b) in enumerate(zip(x, y)):
            if a is not None and b is not None:
                self.X[i].append(a)
                self.Y[i].append(b)
        self.axes[0].cla()
        for x, y, fmt in zip(self.X, self.Y, self.fmts):
            self.axes[0].plot(x, y, fmt)
        self.config_axes()
        display.display(self.fig)
        display.clear_output(wait=True)

#在n个变量上累加
class Accumulator:
    def __init__(self, n):
        self.data = [0.0] * n
    def add(self, *args):
        self.data = [a + float(b) for a, b in zip(self.data, args)]
    def reset(self):
        self.data = [0.0] * len(self.data)
    def __getitem__(self, idx):
        return self.data[idx]
    
#读取标签
def read_csv_labels(filename) :
    with open(filename,'r') as f :
        #跳过文件头行(列名)
        lines=f.readlines()[1:]
    tokens=[l.rstrip().split(',') for l in lines]
    #返回(文件名:标签)字典
    return dict(((name,label) for name,_,label in tokens))

#将文件复制到目标目录
def copyfile(filename,target_dir) :
    os.makedirs(target_dir,exist_ok=True)
    shutil.copy(filename,target_dir)

#复制拆分训练集和验证集,返回验证集中每个类别样本数
def reorganize_train_valid(data_dir,labels,valid_ratio) :
    #验证集中每个类别的样本数
    n_min=collections.Counter(labels.values()).most_common()[-1][1]
    n_valid_per_label=max(1,math.floor(n_min*valid_ratio))

    label_count={}  #记录已在验证集中的每个类别样本数
    for train_file in os.listdir(os.path.join(data_dir,'train')) :
        label=labels[train_file]

        filename=os.path.join(data_dir,'train',train_file)
        copyfile(filename,os.path.join(data_dir,'train_and_valid','train_valid',label))    #train_valid  训练+验证

        if label not in label_count or label_count[label]<n_valid_per_label :
            copyfile(filename,os.path.join(data_dir,'train_and_valid','valid',label))    #valid  验证集
            label_count[label]=label_count.get(label,0)+1

        else :
            copyfile(filename,os.path.join(data_dir,'train_and_valid','train',label))    #train  训练集

    return n_valid_per_label

#重新组织数据文件结构
def reorganize_data(data_dir,valid_ratio) :
    #(文件名:标签)字典
    labels=read_csv_labels(os.path.join(data_dir,'labels.csv'))
    reorganize_train_valid(data_dir,labels,valid_ratio)


#单批次损失(向量形式)
loss=nn.CrossEntropyLoss(reduction='none')

#总损失
def evaluate_loss(data_iter,net,devices) :
    l_sum,n=0.0,0   #总损失，总样本数
    for features, labels in data_iter :
        features,labels=features.to(devices[0]),labels.to(devices[0])
        outputs=net(features)
        l=loss(outputs,labels)
        l_sum+=l.sum()
        n+=labels.numel()
    return (l_sum/n).to('cpu')



#训练函数(输出网络)
def train(net,train_iter,valid_iter,num_epochs,lr,wd,devices,lr_period,lr_decay) :
    #并行计算
    net=nn.DataParallel(net,device_ids=devices).to(devices[0])
    #优化器
    trainer=torch.optim.SGD((param for param in net.parameters() if param.requires_grad),
                            lr=lr,momentum=0.9,weight_decay=wd)
    #学习率调度器
    scheduler=torch.optim.lr_scheduler.StepLR(trainer,lr_period,lr_decay)
    #批次数，计时器
    num_batches,timer=len(train_iter),Timer()
    #图例
    legend=['train loss']
    if valid_iter :
        legend.append('valid loss')
    animator=Animator(xlabel='epoch',xlim=[1,num_epochs],legend=legend)

    #训练循环
    for epoch in range(num_epochs) :
        #累加计数器:总损失，样本数
        metric=Accumulator(2)
        for i,(features, labels) in enumerate(train_iter):
            #开始计时
            timer.start()
            #数据移动到设备
            features,labels=features.to(devices[0]),labels.to(devices[0])
            #梯度清零
            trainer.zero_grad()

            output=net(features)
            #单批次总损失
            l=loss(output,labels).sum()
            #反向传播
            l.backward()
            #优化器执行一步更新
            trainer.step()
            #更新计数
            metric.add(l,labels.shape[0])
            #停止计时
            timer.stop()

            #动画器更新频率
            if (i+1)%(num_batches//5)==0 or i==num_batches-1 :
                animator.add(epoch+(i+1)/num_batches,(metric[0]/metric[1],None))

        measures=f"train loss {metric[0]/metric[1]:.3f}"
        if valid_iter :
            valid_loss=evaluate_loss(valid_iter,net,devices)
            animator.add(epoch+1,(None,valid_loss.detach().cpu()))
        #学习率调度器一步更新
        scheduler.step()

    if valid_iter :
        measures+=f",valid loss {valid_loss:.3f}"
    print(measures+f"\n{metric[0]*num_epochs/timer.sum():.1f}"+f"examples/sec on {str(devices)}")

#评估测试集准确率
def evaluate_accuracy(data_iter,net,devices) :
    acc_num,n=0,0
    with torch.no_grad() :
        for data, label in data_iter :
            data,label=data.to(devices[0]),label.to(devices[0])
            output=torch.nn.functional.softmax(net(data),dim=1)
            prediction=output.argmax(dim=1)
            acc_num+=(prediction==label).sum().cpu().item()
            n+=label.numel()
    print(f"accuracy rate:{acc_num/n:.3f}")
