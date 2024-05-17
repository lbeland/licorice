*******************************************************************************
Custom Drivers
*******************************************************************************

Users may extend LiCoRICE by setting the ``LICORICE_TEMPLATE_PATH`` environment variable to add or overwrite template files, including drivers. In this way, users may write their own drivers to interface with peripherals. Drivers are represented as `Cython extension types <https://docs.cython.org/en/stable/src/userguide/extension_types.html>`_ which allow interfacing with C libraries while exposing drivers as encapsulated Python classes.

Drivers can also be added to LiCoRICE directly by adding an extension type to the correct folder in the LiCoRICE source code and compiling from source. Sink drivers must be added to the ``licorice/templates/sink_drivers/`` folder and source drivers to ``licorice/templates/source _drivers/``.


Specification
===============================================================================

A LiCoRICE custom driver has a few mandatory requirements.

 * Drivers must constitute of a set of files in one folder with the driver's name with the following structure:

  .. code-block::

    <driver-name>
    |-- __init__.pxd
    |-- <driver-name>.pxd.j2
    |-- <driver-name>.pyx.j2


 * Driver extension type classes must subclass the appropriate ``source_driver.SourceDriver`` or ``sink_driver.SinkDriver`` abstract class. These classes are implemented in LiCoRICE and can be imported as below if the ``licorice`` package is installed in your virtualenv:

 .. code-block::

  from source_drivers cimport source_driver
  # source_driver.SourceDriver

  from sink_drivers cimport source_driver
  # sink_driver.SinkDriver


 * Driver classes must implement a ``run`` and ``exit_handler`` method which are the ``NotImplemented`` methods of the generic abstract ``SourceDriver`` and ``SinkDriver`` classes.


Example
===============================================================================

The following is an implementation of a parallel port source driver which uses ``pyparallel`` to read in data each tick. The driver files use `Jinja2 templating <https://jinja.palletsprojects.com/en/3.1.x/>`_ in order to embed configuration values. Note that variables for the extension type class are defined in the ``.pxd`` file (like a C header file) and method implementations are defined in the ``.pyx`` file (like a C source file).

An empty ``__init__.pxd`` file must be included in the driver folder so that the driver can be imported into python code as a package.

.. code-block:: cython

  # __init__.pxd

  # must have an empty __init__.pxd file


Then, the ``.pxd.j2`` templated header file defines any variables used the class (use ``cdef object`` to specify Python variables) as well as the method signature for the mandatory ``run`` and ``exit_handler`` methods. Other helper methods can be included here as well.

.. code-block:: cython
  :linenos:

  # parport.pxd.j2

  from libc.stdint cimport uint8_t

  from runner_utils cimport times_t
  from source_drivers cimport source_driver

  cdef class ParportSourceDriver(source_driver.SourceDriver):
      cdef object pport
      cdef float sleep_duration

      cdef size_t run(self, times_t *times, void *inBuf, size_t packetSize, object out_sigs) except *
      cdef void exit_handler(self, int exitStatus) except *


Finally, the ``.pyx.j2`` source file includes the implementation of the ``run`` and ``exit_handler`` methods, as well as a ``__cinit__`` method that sets up any resources needed during realtime execution.

.. code-block:: cython
  :linenos:

  # parport.pyx.j2

  import parallel

  from libc.stdint cimport uint8_t

  from source_drivers cimport source_driver

  cdef class ParportSourceDriver(source_driver.SourceDriver):
      def __cinit__(self):
          self.pport = parallel.Parallel(port={{in_signal['args']['addr']}})
          self.pport.setDataDir(False) # read from data pins, sets PPDATADIR
          self.sleep_duration = {{config["config"]["tick_len"]}} / (2. * 1e6)

      cdef size_t run(self, times_t *times, void *inBuf, size_t packetSize, object out_sigs) except *:
          (<unsigned char *>inBuf)[0] = <unsigned char>self.pport.getData()

  {%- if async %}

          sleep(self.sleep_duration)
  {%- endif %}

          return 1

      cdef void exit_handler(self, int exitStatus) except *:
          pass
