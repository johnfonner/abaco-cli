from reactors.utils import Reactor


def main():
    """Main function"""
    r = Reactor()
    r.logger.debug("Hello this is actor {}".format(r.uid))


if __name__ == '__main__':
    main()
