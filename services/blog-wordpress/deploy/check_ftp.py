#!/usr/bin/env python3
"""Diagnose authenticated FTP data channels without writing or listing remote files."""

import argparse
import ftplib
import os
import ssl


class ExtendedPassive:
    def makepasv(self):
        return ftplib.parse229(self.sendcmd('EPSV'), self.sock.getpeername())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--timeout', type=float, default=10, help='Connection and data socket timeout in seconds (default: 10)')
    parser.add_argument('--port', type=int, default=21, help='FTP control port (default: 21)')
    args = parser.parse_args()
    successful = 0
    for encrypted in (False, True):
        for extended in (True, False):
            name = ('FTPS' if encrypted else 'FTP') + (' EPSV' if extended else ' PASV')
            base = ftplib.FTP_TLS if encrypted else ftplib.FTP
            client_type = type('Probe', (ExtendedPassive, base), {}) if extended else base
            client = client_type(timeout=args.timeout, **({'context': ssl.create_default_context()} if encrypted else {}))
            stage = 'connect'
            try:
                client.connect(os.environ['FTP_SERVER'], args.port)
                stage = 'login and TLS verification' if encrypted else 'login'
                client.login(os.environ['FTP_USERNAME'], os.environ['FTP_PASSWORD'])
                if encrypted:
                    client.prot_p()
                stage = 'directory access'
                client.cwd('blog.marianialessandro.com')
                stage = 'data channel'
                size = 0

                def received(chunk):
                    nonlocal size
                    size += len(chunk)

                client.retrbinary('RETR .ftp-deploy-sync-state.json', received)
                print(f'{name}: PASS state downloaded ({size} bytes)', flush=True)
                successful += 1
            except ftplib.error_perm as error:
                print(f'{name}: FTP {str(error)[:3]} during {stage}', flush=True)
            except Exception as error:
                print(f'{name}: {type(error).__name__} during {stage}', flush=True)
            finally:
                client.close()
    if not successful:
        raise SystemExit('No protocol could download the deployment state; no remote files were changed.')


if __name__ == '__main__':
    main()
