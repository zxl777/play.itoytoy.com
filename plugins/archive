#!/usr/bin/php
<?php
/**
 * @author wapmorgan (wapmorgan@gmail.com)
 */
namespace archive;
function GETTER_FOR($property) { return 'get'.$property; }

if (PHP_SAPI != 'cli')
    exit;

/**
 * Parses $GLOBALS['argv'] for parameters and assigns them to an array.
 *
 * Supports:
 * -e
 * -e <value>
 * --long-param
 * --long-param=<value>
 * --long-param <value>
 * <value>
 *
 * @param array $noopt List of parameters without values
 * @param array $params
 * @return array
 */
function parseParameters($noopt = array(), array $params) {
    $result = array();
    // could use getopt() here (since PHP 5.3.0), but it doesn't work relyingly
    reset($params);
    while (list($tmp, $p) = each($params)) {
        if ($p{0} == '-') {
            $pname = substr($p, 1);
            $value = true;
            if ($pname{0} == '-') {
                // long-opt (--<param>)
                $pname = substr($pname, 1);
                if (strpos($p, '=') !== false) {
                    // value specified inline (--<param>=<value>)
                    list($pname, $value) = explode('=', substr($p, 2), 2);
                }
            }
            // check if next parameter is a descriptor or a value
            $nextparm = current($params);
            if (!in_array($pname, $noopt) && $value === true && $nextparm !== false && $nextparm{0} != '-') list($tmp, $value) = each($params);
            $result[$pname] = $value;
        } else {
            // param doesn't belong to any option
            $result[] = $p;
        }
    }
    return $result;
}

/**
 * Class ArchiveEntry
 * @package archive
 */
class ArchiveEntry implements \ArrayAccess {
    public function __construct($name, $size, $compressedSize, $unixtimeOrDatetime) {
        $this->name = $name;
        $this->size = $size;
        $this->compressedSize = $compressedSize;
        if (is_int($unixtimeOrDatetime))
            $this->unixtime = $unixtimeOrDatetime;
        else
            $this->unixtime = strtotime($unixtimeOrDatetime);
    }
    static public function instantiateFromRarEntry(\RarEntry $e) {
        return new self($e->getName(), $e->getUnpackedSize(), $e->getPackedSize(), $e->getFileTime());
    }
    static public function instantiateFromPharFileInfo(\PharFileInfo $i) {
        return new self($i->getFilename(), $i->getSize(), $i->getCompressedSize(), $i->getMTime());
    }
    public function getDateTime() {
        return date('Y-m-d G:i:s', $this->unixtime);
    }
    public function offsetGet($offset) {
        if (property_exists($this, $offset)) {
            return $this->$offset;
        } else if (method_exists($this, GETTER_FOR($offset))) {
            return call_user_func(array($this, GETTER_FOR($offset)));
        } else {
            throw new \InvalidArgumentException("Undefined property: {$offset}");
        }
    }

    public function offsetExists($offset) {
        return property_exists($this, $offset) || method_exists($this, GETTER_FOR($offset));
    }

    public function offsetUnset($offset) {
    }

    public function offsetSet($offset, $value) {
        $this->$offset = $value;
    }
}

// zip support
if (extension_loaded('zip'))
{
    class ZipArchive implements \Iterator {
        private $archive;
        private $archive_name;
        private $iterator_index = 0;

        public function __construct($archive_name) {
            $this->archive = new \ZipArchive();
            $this->archive->open($archive_name);
            $this->archive_name = $archive_name;
        }
        public function current() {
            if ($stat = $this->archive->statIndex($this->iterator_index)) {
                $entry = new ArchiveEntry($stat['name'], $stat['size'], $stat['comp_size'], $stat['mtime']);
                return $entry;
            }
        }
        public function key() {
            return $this->iterator_index;
        }
        public function next() {
            $this->iterator_index++;
        }
        public function rewind() {
            $this->iterator_index = 0;
        }
        public function valid() {
            return $this->archive->numFiles > $this->iterator_index;
        }
        public function currentBody() {
            return $this->archive->getFromIndex($this->iterator_index);
        }
        public function supportsBunchExtraction() {
            return true;
        }
        public function extract($dir) {
            $this->archive->extractTo($dir);
        }
        public function extractEntry(ArchiveEntry $entry, $dir) {
            $this->archive->extractTo($dir, $entry->name);
        }
    }
}

// rar support
if (extension_loaded('rar'))
{
    class RarArchive implements \Iterator {
        private $archive;
        private $archive_name;
        private $archive_entries;
        private $iterator_index = 0;

        public function __construct($archive_name) {
            $this->archive = \RarArchive::open($archive_name);
            $this->archive_name = $archive_name;
            $this->archive_entries = $this->archive->getEntries();
        }
        public function current() {
            $data = $this->archive_entries[$this->iterator_index];
            $entry = ArchiveEntry::instantiateFromRarEntry($data);
            return $entry;
        }
        public function key() {
            return $this->iterator_index;
        }
        public function next() {
            $this->iterator_index++;
        }
        public function rewind() {
            $this->iterator_index = 0;
        }
        public function valid() {
            return isset($this->archive_entries[$this->iterator_index]);
        }
        public function currentBody() {
            $entry = $this->archive_entries[$this->iterator_index];
            ob_start();
            $stream = $entry->getStream();
            while (!feof($stream)) {
                echo fread($stream, 8192);
            }
            fclose($stream);
            return ob_get_clean();
        }
        public function supportsBunchExtraction() {
            return false;
        }
        public function extractEntry(ArchiveEntry $entry, $dir) {
            $this->archive->getEntry($entry->name)->extract($dir);
        }
    }
}

// phar
// tar
if (extension_loaded('phar')) {
    class PharDataArchive implements \Iterator {
        private $archive;
        private $archive_name;
        private $iterator = 0;
        public function __construct($archive_name) {
            if (strtolower(substr($archive_name, -5)) == '.phar')
                $this->archive = new \Phar($archive_name);
            else
                $this->archive = new \PharData($archive_name);
            $this->archive_name = $archive_name;
            $this->iterator = new \RecursiveIteratorIterator($this->archive);
        }
        public function current() {
            $data = $this->iterator->current();
            $entry = ArchiveEntry::instantiateFromPharFileInfo($data);
            return $entry;
        }
        public function key() {
            return $this->iterator->key();
        }
        public function next() {
            $this->iterator->next();
        }
        public function rewind() {
            $this->iterator->rewind();
        }
        public function valid() {
            return $this->iterator->valid();
        }

        /**
         * @return string
         */
        public function currentBody() {
            // do some inappropriate magic
            // because PHP developers got lazy and forget to write getContents() method
            $ArchiveEntry = $this->current();
            return file_get_contents($this->getFullPathToEntry($ArchiveEntry));
        }
        public function supportsBunchExtraction() {
            return true;
        }
        public function extract($dir) {
            $this->archive->extractTo($dir);
        }
        public function extractEntry(ArchiveEntry $entry, $dir) {
            $this->archive->extractTo($dir, $entry->name);
        }
        public function getFullPathToEntry(ArchiveEntry $entry) { return 'phar://'.$this->archive_name.'/'.$entry->name; }
    }

    class PharArchive extends PharDataArchive {}

    class TarArchive extends PharDataArchive {}
}

define('INDEX', 'index');
define('EXTRACT', 'extract');
define('PRINT', 'print');

$argv = parseParameters(array(), $argv);
if (isset($argv['listFormat'])) {
    define('LIST_FORMAT', $argv['listFormat']);
} else {
    define('LIST_FORMAT', '@name%40s | @size%d | @datetime%s');
}

if (isset($argv['extractDir'])) {
    define('EXTRACT_DIR', realpath($argv['extractDir']));
} else {
    define('EXTRACT_DIR', getcwd().DIRECTORY_SEPARATOR.'output');
}

function main($argc, $argv)
{
    $script = $argv[0];
    if (!isset($argv[1])) {
        //fwrite(STDERR, "Archive parameter must be declared.");
        echo <<<USAGE
 USAGE
  archive [archive] {action} FILES... [--listFormat=] [--extractDir=]
 ACTIONS
  index
   You can get the list of files stored in archive. By passing --listFormat
    option you can specify output format. It has syntax similar to sprintf()
    format. The main improvement is you can specify placeholders like this:
    @placeholder%format where placeholder is an identificator of property for
    array entry. Standart listFormat: '@name%40s | @size%d | @time%s'.
  extract
   Extract archive files to dir. By passing --extractDir option you can
    specify output directory.
  print FILES...
   Print the files contents to standard output. Useful for on-the-fly
    searching.
 FORMATS
  Currently supported formats:
   - zip (via default extension 'zip')
   - phar and tar (via default >=5.3.0 extension 'phar')
   - rar (via 'rar' extension)
 LIST FORMAT
  Here are all available placeholders:
   - name
   - size
   - compressedSize
   - unixtime
   - datetime

USAGE;
exit(0);
    }

    $archive = $argv[1];
    $archive_ext = strtolower(pathinfo($archive, PATHINFO_EXTENSION));
    if ($archive_ext == 'zip') {
        $archive_p = new ZipArchive(realpath($archive));
    } else if ($archive_ext == 'rar') {
        $archive_p = new RarArchive(realpath($archive));
    } else if ($archive_ext == 'phar') {
        $archive_p = new PharArchive(realpath($archive));
    } else if (preg_match('~\.tar(\.gz|\.bz2?)?$~', $archive)) {
        $archive_p = new TarArchive(realpath($archive));
    } else {
        fwrite(STDERR, "Unsupported archive type: ".$archive_ext);
        exit(1);
    }

    if (!isset($argv[2]) || substr($argv[2], 0, 1) == '-')
        $action = INDEX;
    else {
        $action = $argv[2];
        if (!in_array($action, array(
            'index',
            'extract',
            'print'
        ))) {
            $action = INDEX;
        }
    }

    // arguments list
    $arguments = array();
    foreach ($argv as $i => $a) {
        if (is_int($i) && $i > 2) {
            $arguments[] = $argv[$i];
        }
    }

    switch ($action) {
        case INDEX:
            $format = LIST_FORMAT;
            $placeholders = parseFormat($format);
            foreach ($archive_p as $file_e) {
                echo sprintfplc($format.PHP_EOL, $file_e, $placeholders);
            }
        break;
        case 'print':
            foreach ($archive_p as $file_e) {
                if (in_array($file_e->name, $arguments)) {
                    echo $archive_p->currentBody();
                }
            }
        break;
        case EXTRACT:
            if ($archive_p->supportsBunchExtraction()) {
                $archive_p->extract(EXTRACT_DIR);
            } else {
                foreach ($archive_p as $file_e) {
                    $archive_p->extractEntry($file_e, EXTRACT_DIR);
                }
            }
        break;
    }
}

/**
 * Some magic
 */
function parseFormat(&$format) {
    $placeholders = array();
    while (($pos = strpos($format, '@')) !== false) {
        $pos2 = strpos($format, '%', $pos);
        $placeholders[] = substr($format, $pos + 1, $pos2 - $pos - 1);
        $format = substr($format, 0, $pos).substr($format, $pos2);
    }
    return $placeholders;
}

/**
 * Another magic
 */
function sprintfplc($format, $source, $placeholders) {
    $args = array($format);
    foreach ($placeholders as $placeholder) {
        $args[] = $source[$placeholder];
    }
    return call_user_func_array('sprintf', $args);
}

main($argc, $argv);
