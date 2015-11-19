import matplotlib.pyplot as plt
import numpy as np
import subprocess


def run(x):
    return subprocess.check_output(["bash", "-c", x])

optimizer=run("cat nn.log|grep -Po '(?<=optimizer:loss avgError ).*'").decode('utf-8').strip()
tester=run("cat nn.log|grep -Po '(?<=tester:loss avgError ).*'").decode('utf-8').strip()

optimizer = list(map(float, map(str.strip, optimizer.split("\n"))))
tester = list(map(float, map(str.strip, tester.split("\n"))))


optimizer = np.array(optimizer)
optimizer*=10
tester = np.array(tester)

t = np.arange(0.0, 2.0, 0.01)
s = np.sin(2*np.pi*t)
plt.plot(optimizer, label='optimizer')
plt.plot(tester, label='tester')

plt.xlabel('epoch')
plt.ylabel('cross-entropy')
#plt.yscale("log")
plt.title('Loss of Net')
plt.grid(True)
plt.legend()
plt.savefig("loss_plot.svg")
plt.show()
