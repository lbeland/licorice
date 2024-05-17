###############################################################################
Debugging LiCoRICE
###############################################################################


Debug Flag
===============================================================================

Run LiCoRIce with the `--debug` flag:

.. code-block:: bash

    licorice go <model> --debug



Debugging Segmentation Faults:
===============================================================================

Passing the `--debug` flag causes spin in exit handler (only async source for now)

Get the faulted process ID:

.. code-block:: bash

    PID=`ps ax | grep <proc-name> grep -v grep | awk '{print $1}'`


and use gdb to find location of seg fault

.. code-block:: bash

    sudo gdb /proc/$PID/exe $PID
    (gdb) c
    (gdb) where
